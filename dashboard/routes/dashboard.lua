local ipairs = ipairs
local pairs = pairs
local type = type
local xpcall = xpcall
local string_lower = string.lower
local lor = require("lor.index")
local lua_next = next
local json = require "cjson"


local function load_plugin_api(plugin, dashboard_router, store)
    local plugin_api_path = "orange.plugins." .. plugin .. ".api"
    ngx.log(ngx.ERR, "[plugin's api load], plugin_api_path:", plugin_api_path)

    local ok, plugin_api, e
    ok = xpcall(function()
        plugin_api = require(plugin_api_path)
    end, function()
        e = debug.traceback()
    end)
    if not ok or not plugin_api or type(plugin_api) ~= "table" then
        ngx.log(ngx.ERR, "[plugin's api load error], plugin_api_path:", plugin_api_path, " error:", e)
        return
    end

    local plugin_apis
    if plugin_api.get_mode and plugin_api:get_mode() == 2 then
        plugin_apis = plugin_api:get_apis()
    else
        plugin_apis = plugin_api
    end

    for uri, api_methods in pairs(plugin_apis) do
        ngx.log(ngx.INFO, "load route, uri:", uri)
        if type(api_methods) == "table" then
            for method, func in pairs(api_methods) do
                local m = string_lower(method)
                if m == "get" or m == "post" or m == "put" or m == "delete" then
                    dashboard_router[m](dashboard_router, uri, func(store))
                end
            end
        end
    end
end

return function(config, store)
    local dashboard_router = lor:Router()
    local orange_db = require("orange.store.orange_db")

    dashboard_router:get("/", function(req, res, next)
        --- 全局信息
        -- 当前加载的插件，开启与关闭情况
        -- 每个插件的规则条数等
        local data = {}
        local plugins = config.plugins
        data.plugins = plugins

        local plugin_configs = {}
        for i, v in ipairs(plugins) do
            local tmp
            if v ~= "kvstore" then
                tmp = {
                    enable =  orange_db.get(v .. ".enable"),
                    name = v,
                    active_selector_count = 0,
                    inactive_selector_count = 0,
                    active_rule_count = 0,
                    inactive_rule_count = 0
                }
                local plugin_selectors = orange_db.get_json(v .. ".selectors")
                if plugin_selectors then
                    for sid, s in pairs(plugin_selectors) do
                        if s.enable == true then
                            tmp.active_selector_count = tmp.active_selector_count + 1
                            local selector_rules = orange_db.get_json(v .. ".selector." .. sid .. ".rules")
                            if not selector_rules then
                                tmp.active_rule_count = 0
                                tmp.inactive_rule_count = 0
                            else
                                for _, r in ipairs(selector_rules) do
                                    if r.enable == true then
                                        tmp.active_rule_count = tmp.active_rule_count + 1
                                    else
                                        tmp.inactive_rule_count = tmp.inactive_rule_count + 1
                                    end
                                end
                            end
                        else
                            tmp.inactive_selector_count = tmp.inactive_selector_count + 1
                        end
                    end
                end
                plugin_configs[v] = tmp
            else
                tmp = {
                    enable =  orange_db.get(v .. ".enable"),
                    name = v
                }
            end
            plugin_configs[v] = tmp
        end
        data.plugin_configs = plugin_configs

        res:render("index", data)
    end)

    dashboard_router:get("/status", function(req, res, next)
        res:render("status")
    end)

    dashboard_router:get("/monitor", function(req, res, next)
        res:render("monitor")
    end)

    dashboard_router:get("/monitor/rule/statistic", function(req, res, next)
        local rule_id = req.query.rule_id;
        local rule_name = req.query.rule_name or "";
        res:render("monitor-rule-stat", {
            rule_id = rule_id,
            rule_name = rule_name
        })
    end)

    dashboard_router:get("/rewrite", function(req, res, next)
        res:render("rewrite")
    end)

    dashboard_router:get("/redirect", function(req, res, next)
        res:render("redirect")
    end)
    dashboard_router:get("/dynamic_upstream", function(req, res, next)
        local upstream = require "ngx.upstream"

        local upstream_list = upstream.get_upstreams()
        local empty_table = false

        if lua_next(upstream_list) == nil then
            empty_table = true
        end

        local every_upstream_config = {}
        for _, v in ipairs(upstream_list) do
            every_upstream_config[v] = upstream.get_servers(v)
        end

        res:render("dynamic_upstream",{upstreams=upstream_list, empty_table = empty_table, every_upstream_config = json.encode(every_upstream_config)})
    end)
    dashboard_router:get("/rate_limiting", function(req, res, next)
        res:render("rate_limiting")
    end)
    dashboard_router:get("/property_rate_limiting", function(req, res, next)
        res:render("property_rate_limiting")
    end)
    dashboard_router:get("/basic_auth", function(req, res, next)
        res:render("basic_auth/basic_auth")
    end)

    dashboard_router:get("/signature_auth", function(req, res, next)
        res:render("signature_auth/signature_auth")
    end)

    dashboard_router:get("/key_auth", function(req, res, next)
        res:render("key_auth/key_auth")
    end)

    dashboard_router:get("/waf", function(req, res, next)
        res:render("waf")
    end)

    dashboard_router:get("/divide", function(req, res, next)
        res:render("divide")
    end)

    dashboard_router:get("/kvstore", function(req, res, next)
        res:render("kvstore")
    end)

    dashboard_router:get("/help", function(req, res, next)
        res:render("help")
    end)

    --- 加载其他"可用"插件API
    local available_plugins = config.plugins
    if not available_plugins or type(available_plugins) ~= "table" or #available_plugins<1 then
        ngx.log(ngx.ERR, "no available plugins, maybe you should check `orange.conf`.")
    else
        for _, p in ipairs(available_plugins) do
            load_plugin_api(p, dashboard_router, store)
        end
    end

    return dashboard_router
end


