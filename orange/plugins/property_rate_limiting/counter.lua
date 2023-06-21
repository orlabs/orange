local resty_lock = require("resty.lock")
local json = require("orange.utils.json")
local plugin_config =  require("orange.plugins.property_rate_limiting.plugin")

local ngx_log = ngx.log
local redis = require("orange.plugins.base_redis")
local cache = "property_rate_limiting"

-- default exprired time for different periods
local EXPIRE_TIME = {
  Second = 60, -- 59s+
  Minute = 180, -- 120s+
  Hour = 3720, -- 120s+
  Day = 86520 -- 120s+
}


local _M = {}

function _M.get(key)
    return redis.get(cache, key)
end

function _M.set(key, value, expired)
    return redis.set(cache, key, value, expired)
end

function _M.incr(key, value, expired)
    return redis.incr(cache, key, value, EXPIRE_TIME[expired])
end

function _M.delete(key)
    redis.delete(cache, key)
end


return _M
