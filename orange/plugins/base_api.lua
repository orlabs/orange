local tonumber = tonumber
local type = type
local pairs = pairs
local setmetatable = setmetatable
local string_upper = string.upper
local string_lower = string.lower
local string_format = string.format

local _METHODS = {
    GET = true,
    POST = true,
    PUT = true,
    DELETE = true,
    PATCH = true
}


local BaseAPI = {}

function BaseAPI:new(name, mode)
    local instance = {}
    instance._name = name
    instance._apis = {}
    instance._mode = tonumber(mode) or 1

    setmetatable(instance, { __index = self })
    instance:build_method()
    return instance
end

function BaseAPI:get_name()
    return self._name
end

function BaseAPI:get_mode()
    return self._mode
end

function BaseAPI:get_apis()
    return self._apis
end

function BaseAPI:set_api(path, method, func)
    if not path or not method or not func then
        return ngx.log(ngx.ERR, "params should not be nil.")
    end

    if type(path) ~= "string" or type(method) ~= "string" or type(func) ~= "function" then
        return ngx.log(ngx.ERR, "params type error")
    end 

    method = string_upper(method)
    if not _METHODS[method] then 
        return ngx.log(ngx.ERR, string_format("[%s] method is not supported yet.", method))
    end
    
    self._apis[path] = self._apis[path] or {}
    self._apis[path][method] = func
end

function BaseAPI:build_method()
    for m, _ in pairs(_METHODS) do
        m = string_lower(m)
        ngx.log(ngx.INFO, "attach method " .. m .. " to BaseAPI")
        BaseAPI[m] = function(myself, path, func)
            BaseAPI.set_api(myself, path, m, func)
        end
    end
end

function BaseAPI:merge_apis(apis)
    if apis and type(apis) == "table" then
        for path, methods in pairs(apis) do
            if methods and type(methods) == "table" then
                for m, func in pairs(methods) do
                    m = string_lower(m)
                    ngx.log(ngx.INFO, "merge method, path: ", path, " method:", m)
                    self:set_api(path, m, func)
                end
            end
        end
    end
end


return BaseAPI
