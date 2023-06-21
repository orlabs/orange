local redis_c = require "resty.redis"

local _M = {}

local commands = {
    "append",            "auth",              "bgrewriteaof",
    "bgsave",            "bitcount",          "bitop",
    "blpop",             "brpop",
    "brpoplpush",        "client",            "config",
    "dbsize",
    "debug",             "decr",              "decrby",
    "del",               "discard",           "dump",
    "echo",
    "eval",              "exec",              "exists",
    "expire",            "expireat",          "flushall",
    "flushdb",           "get",               "getbit",
    "getrange",          "getset",            "hdel",
    "hexists",           "hget",              "hgetall",
    "hincrby",           "hincrbyfloat",      "hkeys",
    "hlen",
    "hmget",              "hmset",      "hscan",
    "hset",
    "hsetnx",            "hvals",             "incr",
    "incrby",            "incrbyfloat",       "info",
    "keys",
    "lastsave",          "lindex",            "linsert",
    "llen",              "lpop",              "lpush",
    "lpushx",            "lrange",            "lrem",
    "lset",              "ltrim",             "mget",
    "migrate",
    "monitor",           "move",              "mset",
    "msetnx",            "multi",             "object",
    "persist",           "pexpire",           "pexpireat",
    "ping",              "psetex",            "psubscribe",
    "pttl",
    "publish",      --[[ "punsubscribe", ]]   "pubsub",
    "quit",
    "randomkey",         "rename",            "renamenx",
    "restore",
    "rpop",              "rpoplpush",         "rpush",
    "rpushx",            "sadd",              "save",
    "scan",              "scard",             "script",
    "sdiff",             "sdiffstore",
    "select",            "set",               "setbit",
    "setex",             "setnx",             "setrange",
    "shutdown",          "sinter",            "sinterstore",
    "sismember",         "slaveof",           "slowlog",
    "smembers",          "smove",             "sort",
    "spop",              "srandmember",       "srem",
    "sscan",
    "strlen",       --[[ "subscribe",  ]]     "sunion",
    "sunionstore",       "sync",              "time",
    "ttl",
    "type",         --[[ "unsubscribe", ]]    "unwatch",
    "watch",             "zadd",              "zcard",
    "zcount",            "zincrby",           "zinterstore",
    "zrange",            "zrangebyscore",     "zrank",
    "zrem",              "zremrangebyrank",   "zremrangebyscore",
    "zrevrange",         "zrevrangebyscore",  "zrevrank",
    "zscan",
    "zscore",            "zunionstore",       "evalsha"
}

local mt = { __index = _M }

local function is_redis_null( res )
    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end

    return false
end

function _M.close_redis(self, redis)
    if not redis then
        return
    end
    --释放连接(连接池实现)
    local pool_max_idle_time = self.pool_max_idle_time --最大空闲时间 毫秒
    local pool_size = self.pool_size --连接池大小

    local ok, err = redis:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.say("set keepalive error : ", err)
    end
end

-- change connect address as you need
function _M.connect_mod( self, redis )
    redis:set_timeout(self.timeout)
    local ok, err = redis:connect(self.host, self.port)
    if not ok then
        ngx.say("connect to redis error : ", err)
        return self:close_redis(redis)
    end

    if self.password then ----密码认证
        --这里解释一下 tcpsock:getreusedtimes() 方法，如果当前连接不是从内建连接池中获取的，该方法总是返回 0 ，
        --也就是说，该连接还没有被使用过。如果连接来自连接池，那么返回值永远都是非零。所以这个方法可以用来确认当前连接是否来自池子。
        --对于 Redis 授权，实际上只需要建立连接后，首次认证一下，后面只需直接使用即可。
        --换句话说，从连接池中获取的连接都是经过授权认证的，只有新创建的连接才需要进行授权认证。
        --所以大家就看到了 count, err = red:get_reused_times() 这段代码，并有了下面 if 0 == count then 的判断逻辑。
        local count, err = redis:get_reused_times()
        if 0 == count then ----新建连接，需要认证密码
            ok, err = redis:auth(self.password)
            if not ok then
                ngx.say("failed to auth: ", err)
                return
            end
        elseif err then  ----从连接池中获取连接，无需再次认证密码
            ngx.say("failed to get reused times: ", err)
            return
        end
    end

    return ok,err;
end

function _M.init_pipeline( self )
    self._reqs = {}
end

function _M.commit_pipeline( self )
    local reqs = self._reqs

    if nil == reqs or 0 == #reqs then
        return {}, "no pipeline"
    else
        self._reqs = nil
    end

    local redis, err = redis_c:new()

    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok then
        return {}, err
    end

    redis:init_pipeline()
    for _, vals in ipairs(reqs) do
        local fun = redis[vals[1]]
        table.remove(vals , 1)

        fun(redis, unpack(vals))
    end

    local results, err = redis:commit_pipeline()
    if not results or err then
        return {}, err
    end

    if is_redis_null(results) then
        results = {}
        ngx.log(ngx.WARN, "is null")
    end
    -- table.remove (results , 1)

    --self.set_keepalive_mod(redis)
    self:close_redis(redis)

    for i,value in ipairs(results) do
        if is_redis_null(value) then
            results[i] = nil
        end
    end

    return results, err
end


local function do_command(self, cmd, ... )
    if self._reqs then
        table.insert(self._reqs, {cmd, ...})
        return
    end

    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok or err then
        return nil, err
    end

    redis:select(self.db_index)

    local fun = redis[cmd]
    local result, err = fun(redis, ...)
    if not result or err then
        -- ngx.log(ngx.ERR, "pipeline result:", result, " err:", err)
        return nil, err
    end

    if is_redis_null(result) then
        result = nil
    end

    --self.set_keepalive_mod(redis)
    self:close_redis(redis)

    return result, err
end

for i = 1, #commands do
    local cmd = commands[i]
    _M[cmd] =
            function (self, ...)
                return do_command(self, cmd, ...)
            end
end

function _M.new(self, opts)
    opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 1000) or 1000
    local db_index= opts.db_index or 4
    local host = opts.host or '127.0.0.1'
    local port = opts.port or 6379
    local password = opts.password
    local pool_max_idle_time = opts.pool_max_idle_time or 60000
    local pool_size = opts.pool_size or 100

    return setmetatable({
        timeout = timeout,
        db_index = db_index,
        host = host,
        port = port,
        password = password,
        pool_max_idle_time = pool_max_idle_time,
        pool_size = pool_size,
        _reqs = nil
    }, mt)
end

return _M
