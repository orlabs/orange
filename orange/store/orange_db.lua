local cjson = require "cjson"
local orange_data = ngx.shared.orange_data


local _M = {}


-- 从缓存获取不存在时更新并返回
function _M.get_or_load(key, cb)
    local value, err
    value = _M.get(key)
    if not value then
        value, err = cb(key)
        if err then
            ngx.log(ngx.ERR, "METHOD:[get_or_load] KEY:[", key, "], callback get date error:", err)
            return err, nil
        elseif value then
            local ok, err = _M.set(key, value)
            if not ok then
                ngx.log(ngx.ERR, "METHOD:[get_or_load] KEY:[", key, "], update local error:", err)
            end
        end
    end
    return nil, value
end

-- 保存到存储系统并更新本地缓存
function _M.save_and_update(key, value, cb)
    local result = cb(key, value) -- true or false
    if result then
        local ok, err = _M.set(key, value)
        if err or not ok then
            ngx.log(ngx.ERR, "METHOD:[save_and_update] KEY:[", key, "], update error:", err)
            return false
        end

        return true
    else
        ngx.log(ngx.ERR, "METHOD:[save_and_update] KEY:[", key, "], save error")
        return false
    end
end

-- 从存储获取并更新缓存
function _M.load_and_set(key, cb)
    local err, value = cb(key)

    if err or not value then
        ngx.log(ngx.ERR, "METHOD:[load_and_set] KEY:[", key, "], load error:", err)
        return false
    else
        local ok, errr = _M.set(key, value)
        if errr or not ok then
            ngx.log(ngx.ERR, "METHOD:[load_and_set] KEY:[", key, "], set error:", errr)
            return false
        end

        return true
    end
end


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
    orange_data:delete(key)
end

function _M.delete_all()
    orange_data:flush_all()
    orange_data:flush_expired()
end


return _M
