local json = require("orange.utils.json")
local redis = require("orange.plugins.base_redis")
local cache = "orange_data"

local _M = {}

function _M._get(key)
    return redis.get_string(cache, key)
end

function _M.get_json(key)
    local value, f = _M._get(key)
    if value then
        value = json.decode(value)
    end
    return value, f
end

function _M._set(key, value)
    return redis.set(cache, key, value)
end

function _M.set(key, value, expired)
    return redis.set(cache, key, value, expired)
end

function _M.set_json(key, value)
    if value then
        value = json.encode(value)
    end
    return _M._set(key, value)
end

function _M.incr(key, value)
    return redis:incr(cache, key, value)
end

function _M.delete(key)
    return redis.delete(cache, key)
end

return _M
