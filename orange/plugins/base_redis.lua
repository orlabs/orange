---
--- Generated by Luanalysis
--- Created by Jessica.
--- DateTime: 2021/6/10 14:50
---
local redis = require("orange.utils.redis")
local config_loader = require("orange.utils.config_loader")

local BaseRedis = {}
local env_orange_conf = os.getenv("ORANGE_CONF")
local conf_file_path = env_orange_conf or ngx.config.prefix().. "/conf/orange.conf"
local context = config_loader.load(conf_file_path)
local cache = redis:new({
    host = context.redis.host,
    port = context.redis.port,
    password = context.redis.password,
    db_index = context.redis.db_index,
});

function BaseRedis.get(cache_prefix, key)
    key = cache_prefix .. ":" .. key
    local res, err = cache:get(key)
    if err then
        ngx.log(ngx.ERR, "failed to get Redis key: ", err)
        return nil
    end
    return tonumber(res)
end

function BaseRedis.get_string(cache_prefix, key)
    key = cache_prefix .. ":" .. key
    local res, err = cache:get(key)
    if err then
        ngx.log(ngx.ERR, "failed to get Redis key: ", err)
        return nil
    end
    return res
end

function BaseRedis.set(cache_prefix, key, value, ttl)
    key = cache_prefix .. ":" .. key
    local res, err
    if ttl then
        res, err = cache:setex(key, ttl, value)
    else
        res, err = cache:set(key, value)
    end
    if err then
        ngx.log(ngx.ERR, "failed to set Redis key: ", err)
        return nil
    end
    return res
end

function BaseRedis.setnx(cache_prefix, key, value, ttl)
    key = cache_prefix .. ":" .. key
    local res, err
    if ttl then
        res, err = cache:setex(key, ttl, value)
    else
        res, err = cache:setnx(key, value)
    end
    if err then
        ngx.log(ngx.ERR, "failed to setnx Redis key: ", err)
        return nil
    end
    return res
end

--red:incr(key, increment)：将key的值加上increment，返回增加后的结果。如果key不存在，会先将它的值设为0再执行自增操作。如果key的值不能被解释为整数，则会返回错误。
--red:incrby(key, increment)：将key的值加上increment，返回增加后的结果。与red:incr不同的是，它可以指定增加的数量，而不是固定增加1。如果key不存在，会先将它的值设为0再执行自增操作。如果key的值不能被解释为整数，则会返回错误。
function BaseRedis.incr(cache_prefix, key, delta, ttl)
    key = cache_prefix .. ":" .. key
    ngx.log(ngx.ERR, "incr delta: ", delta)
    local res, err
    if ttl then
        res, err = cache:incrby(key, delta or 1)
        cache:expire(key, ttl)
    else
        res, err = cache:incrby(key, delta or 1)
    end
    if err then
        ngx.log(ngx.ERR, "failed to incr Redis key: ", err)
        return nil
    end
    return res
end

function BaseRedis.delete(cache_prefix, key)
    key = cache_prefix .. ":" .. key
    local res, err = cache:del(key)
    return res
end

function BaseRedis.get_keys(cache_prefix)
    local res, err = cache:keys(cache_prefix)
    return res
end

function BaseRedis.scan(prefix, cursor, count)
    prefix = prefix .. ":*"
    local res, err = cache:scan(cursor, "count", count, "match", prefix)
    if not res then
        ngx.log(ngx.ERR, "failed to scan: ", err)
        return
    end
    local cursor, keys, err = unpack(res)
    return cursor, keys, err
end

return BaseRedis

