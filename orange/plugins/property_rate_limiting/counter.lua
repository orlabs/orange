local cjson = require("cjson")
local resty_lock = require("resty.lock")
local plugin_config =  require("orange.plugins.property_rate_limiting.plugin")

local ngx_log = ngx.log
local cache = ngx.shared.property_rate_limiting

-- default exprired time for different periods
local EXPIRE_TIME = {
  Second = 60, -- 59s+
  Minute = 180, -- 120s+
  Hour = 3720, -- 120s+
  Day = 86520 -- 120s+
}


local _M = {}

function _M.get(key)
    return cache:get(key)
end

function _M.set(key, value, expired)
    return cache:set(key, value, expired or 0)
end

function _M.get_json(key)
    local value, f = _M.get(key)
    if value then
        value = cjson.decode(value)
    end

    return value, f
end

function _M.set_json(key, value, expired)
    if value then
        value = cjson.encode(value)
    end

    return _M.set(key, value, expired)
end

function _M.incr(key, value, period)
    local v = _M.get(key)
    if not v then
       _M.set(key, 0, EXPIRE_TIME[period])
    end
    return cache:incr(key, value)
end

function _M.delete(key)
    cache:delete(key)
end

function _M.get_or_set(key, cb)
    local value = _M.get(key)
    if value then return value end

    local lock, err = resty_lock:new(plugin_config.shared_dict_rw_lock_name, {
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
