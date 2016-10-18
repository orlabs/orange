local type = type
local ipairs = ipairs
local setmetatable = setmetatable
local encode_base64 = ngx.encode_base64
local string_lower = string.lower
local string_format = string.format
local string_gsub = string.gsub
local lor = require("lor.index")


local function auth_failed(res)
    res:status(401):json({
        success = false,
        msg = "Not Authorized."
    })
end

local function get_encoded_credential(origin)
    local result = string_gsub(origin, "^ *[B|b]asic *", "")
    result = string_gsub(result, "( *)$", "")

    return result
end



local _M = {}

function _M:new(config, store)
    local instance = {}
    instance.config = config
    instance.store = store
    instance.app = lor()

    setmetatable(instance, { __index = self })
    instance:build_app()
    return instance
end

function _M:build_app()
    local config = self.config
    local store = self.store
    local app = self.app
    local router = require("api.router")

    local auth_enable = config and config.api and config.api.auth_enable
    local credentials = config and config.api and config.api.credentials
    local illegal_credentials = (not credentials or type(credentials) ~= "table" or #credentials < 1)

    -- basic-auth middleware
    app:use(function(req, res, next)
        if not auth_enable then return next() end
        if illegal_credentials  then return auth_failed(res) end

        local authorization = req.headers["Authorization"]
        if type(authorization) == "string" and authorization ~= "" then
            local encoded_credential = get_encoded_credential(authorization)

            for i, v in ipairs(credentials) do
                local allowd = encode_base64(string_format("%s:%s", v.username, v.password))
                if allowd == encoded_credential then
                    next()
                    return
                end
            end
        end
            
        auth_failed(res)
    end)

    -- routes
    app:use(router(config, store)())

    -- 404 error
    app:use(function(req, res, next)
        if req:is_found() ~= true then
            res:status(404):json({
                success = false,
                msg = "404! sorry, not found."
            })
        end
    end)

    -- error handle middleware
    app:erroruse(function(err, req, res, next)
        ngx.log(ngx.ERR, err)
        res:status(500):json({
            success = false,
            msg = "500! unknown error."
        })
    end)
end

function _M:get_app()
    return self.app
end

return _M
