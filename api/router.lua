local ipairs = ipairs
local pairs = pairs
local type = type
local require = require
local pcall = pcall
local string_lower = string.lower
local lor = require("lor.index")


local function load_plugin_api(plugin, api_router, store)
    local plugin_api_path = "orange.plugins." .. plugin .. ".api"
    local ok, plugin_api = pcall(require, plugin_api_path)

    if not ok or not plugin_api or type(plugin_api) ~= "table" then
        ngx.log(ngx.ERR, "[plugin's api load error], plugin_api_path:", plugin_api_path)
        return
    end

    for uri, api_methods in pairs(plugin_api) do
        ngx.log(ngx.INFO, "load route, uri:", uri)
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
            local tmp = {
                enable =  (v=="stat") and true or (orange_db.get(v .. ".enable") or false),
                name = v,
                active_rule_count = 0,
                inactive_rule_count = 0
            }

            local plugin_rules = orange_db.get_json(v .. ".rules")
            if plugin_rules then
                for j, r in ipairs(plugin_rules) do
                    if r.enable == true then
                        tmp.active_rule_count = tmp.active_rule_count + 1
                    else
                        tmp.inactive_rule_count = tmp.inactive_rule_count + 1
                    end
                end
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

