local cjson = require("cjson")
local orange_data = ngx.shared.orange_data


local _M = {}

function _M._get(key)
    return orange_data:get(key)
end

function _M.get_json(key)
    local value, f = _M._get(key)
    if value then
        value = cjson.decode(value)
    end
    return value, f
end

function _M.get(key)
    return _M._get(key)
end

function _M._set(key, value)
    return orange_data:set(key, value)
end

function _M.set_json(key, value)
    if value then
        value = cjson.encode(value)
    end
    return _M._set(key, value)
end

function _M.set(key, value)
    -- success, err, forcible
    return _M._set(key, value)
end

function _M.incr(key, value)
    return orange_data:incr(key, value)
end

function _M.delete(key)
    return orange_data:delete(key)
end

function _M.delete_all()
    orange_data:flush_all()
    orange_data:flush_expired()
end


return _M
