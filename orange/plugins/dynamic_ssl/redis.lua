--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/5/19
-- Time: 10:34
-- To change this template use File | Settings | File Templates.
--

local redis = require "resty.redis"
local log = require "orange.plugins.dynamic_ssl.logger"

local errlog = log.errlog
local config = context.config.cache_redis

local RedisFactor = {}
RedisFactor.info = {}
RedisFactor.config ={
    max_idle_timeout = config.pool_config.max_idle_timeout or 10000,
    pool_size = config.pool_config.pool_size or 1000,
    timeout = config.timeout or 1000
}


function RedisFactor:new(host,port,auth,record_redis_info)
    local red = redis:new()
    local timeout =  self.config.timeout
    local connect_config = config.connect_config
    local host = host or connect_config.host
    local port = port or connect_config.port
    local auth = auth or connect_config.auth
    local record = record_redis_info or config.record_redis_info

    red:set_timeout(timeout)
    local ok, err = red:connect(host, port)

    if not ok then
        errlog("failed to connect: ", err)
        return false
    end

    if auth then
        local res,err = red:auth(auth)
        if not res then
            errlog("failed to authenticate: ", err)
            return false
        end
    end

    if record then

        local t = {}
        t.lowwer_level_config = RedisFactor.config
        t.connection_config  = {
            host=host,
            port=port,
            auth=auth,
        }

        self.info[red] = t

    end

    return red
end

RedisFactor.get_redis_obj_info = function(red)
    local json = require "cjson"

    local t = RedisFactor.info[red]
    if not t then
        return nil,"[x] this redis obj not record..."
    end

    t.reused_times = red:get_reused_times()
    return json.encode(t)
end

function RedisFactor:release_to_pool(red)
    red:set_keepalive(self.config.max_idle_timeout,self.config.pool_size)
end

return RedisFactor