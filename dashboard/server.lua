local string_find = string.find
local session_middleware = require("lor.lib.middleware.session")
local check_login_middleware = require("dashboard.middleware.check_login")
local check_is_admin_middleware = require("dashboard.middleware.check_is_admin")
local dashboard_router = require("dashboard.routes.dashboard")
local auth_router = require("dashboard.routes.auth")
local admin_router = require("dashboard.routes.admin")
local lor = require("lor.index")

local _M = {}

function _M:new(config, store, views_path)
    local instance = {}
    instance.config = config
    instance.store = store
    instance.views_path = views_path
    instance.app = lor()

    setmetatable(instance, { __index = self })
    instance:build_app()
    return instance
end

function _M:build_app()
    local config = self.config
    local store = self.store
    local views_path = self.views_path
    local app = self.app

    app:conf("view enable", true)
    app:conf("view engine",  "tmpl")
    app:conf("view ext", "html")
    app:conf("views",   views_path or "./dashboard/views")

    -- support authorization for dashboard
    if config.dashboard and config.dashboard.auth and config.dashboard.auth == true then
        -- session support
        app:use(session_middleware({
            secret = config.dashboard.session_secret or "default_session_secret",
            timeout = config.dashboard.session_timeout or 3600 -- default session timeout is 3600 seconds
        }))
        -- intercepter: login or not
        app:use(check_login_middleware(config.dashboard.whitelist))
        -- auth router
        app:use("auth", auth_router(config)())

        -- check if the current user is admin
        app:use(check_is_admin_middleware())
        -- admin router
        app:use("admin", admin_router(config)())
    end

    -- routes
    app:use(dashboard_router(config, store)())

    -- 404 error
    app:use(function(req, res, next)
        if req:is_found() ~= true then
            if string_find(req.headers["Accept"], "application/json") then
                res:status(404):json({
                    success = false,
                    msg = "404! sorry, not found."
                })
            else
                res:status(404):send("404! sorry, not found. " .. req.path or "")
            end
        end
    end)

    -- error handle middleware
    app:erroruse(function(err, req, res, next)
        ngx.log(ngx.ERR, err)

        if string_find(req.headers["Accept"], "application/json") then
            res:status(500):json({
                success = false,
                msg = "500! unknown error."
            })
        else
            res:status(500):send("unknown error")
        end
    end)
end

function _M:get_app()
    return self.app
end

return _M
