local resty_lock = require("resty.lock")
local json = require("orange.utils.json")
local redis = require("orange.plugins.base_redis")
local ngx_log = ngx.log
local cache = "rate_limiting"

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
    return redis.set(cache, key, value, expired or 0)
end

function _M.get_json(key)
    local value, f = _M.get(key)
    if value then
        value = json.decode(value)
    end

    return value, f
end

function _M.set_json(key, value, expired)
    if value then
        value = json.encode(value)
    end

    return _M.set(key, value, expired)
end

function _M.incr(key, value, expired)
    local v = _M.get(key)
    if not v then
       _M.set(key, 0, EXPIRE_TIME[expired])
    end
    return redis.incr(cache, key, value, EXPIRE_TIME[expired])
end

function _M.delete(key)
    redis.delete(cache, key)
end

function _M.get_or_set(key, cb)
    local value = _M.get(key)
    if value then return value end

    local lock, err = resty_lock:new("rate_limit_counter_lock", {
        exptime = 10,
        timeout = 5
    })
    if not lock then
        ngx_log(ngx.ERR, "resty_lock:new error! error: ", err)
        return
    end

    local elapsed, err = lock:lock(key)
    if not elapsed then
        ngx_log(ngx.ERR, "failed to acquire lock: ", err)
    end

    value = _M.get(key)
    if not value then
        value = cb()
        if value then
            local ok, err = _M.set(key, value)
            if not ok then
                ngx_log(ngx.ERR, err)
            end
        end
    end

    local ok, err = lock:unlock()
    if not ok and err then
        ngx_log(ngx.ERR, "failed to release lock: ", err)
    end

    return value
end


return _M
