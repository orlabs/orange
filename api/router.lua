local ipairs = ipairs
local pairs = pairs
local type = type
local require = require
local xpcall = xpcall
local string_lower = string.lower
local lor = require("lor.index")


local function load_plugin_api(plugin, api_router, store)
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
        -- ngx.log(ngx.INFO, "load route, uri:", uri)
        if type(api_methods) == "table" then
            for method, func in pairs(api_methods) do
                local m = string_lower(method)
                if m == "get" or m == "post" or m == "put" or m == "delete" then
                    api_router[m](api_router, uri, func(store))
                end
            end
        end
    end
end

return function(config, store)
    local api_router = lor:Router()
    local stat_api = require("orange.plugins.stat.api")
    local orange_db = require("orange.store.orange_db")

    --- 插件信息
    -- 当前加载的插件，开启与关闭情况, 每个插件的规则条数等
    api_router:get("/plugins", function(req, res, next)
        local available_plugins = config.plugins

        local plugins = {}
        for i, v in ipairs(available_plugins) do
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
                            for _, r in ipairs(selector_rules) do
                                if r.enable == true then
                                    tmp.active_rule_count = tmp.active_rule_count + 1
                                else
                                    tmp.inactive_rule_count = tmp.inactive_rule_count + 1
                                end
                            end
                        else
                            tmp.inactive_selector_count = tmp.inactive_selector_count + 1
                        end
                    end
                end
            else
                tmp = {
                    enable =  (v=="stat") and true or (orange_db.get(v .. ".enable") or false),
                    name = v
                }
            end
            
            plugins[v] = tmp
        end

        res:json({
            success = true,
            data = {
                plugins = plugins
            }
        })
    end)

  
    --- 加载其他"可用"插件API
    local available_plugins = config.plugins
    if not available_plugins or type(available_plugins) ~= "table" or #available_plugins<1 then
        return api_router
    end

    for i, p in ipairs(available_plugins) do
        load_plugin_api(p, api_router, store)
    end

    return api_router
end

