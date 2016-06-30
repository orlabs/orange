local ipairs = ipairs
local pairs = pairs
local require = require
local table_insert = table.insert
local string_lower = string.lower
local lor = require("lor.index")

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

    --- 全局统计信息
    api_router:get("/stat/status", stat_api["/stat/status"])


    --- 加载其他"可用"插件API
    local available_plugins = config.plugins
    if not available_plugins or type(available_plugins) ~= "table" or #available_plugins<1 then
        return api_router
    end

    for i, p in ipairs(available_plugins) do
        local plugin_api_path = "orange.plugins." .. p .. ".api"
        local ok, plugin_api = pcall(require, plugin_api_path)

        if not ok then
            ngx.log(ngx.ERR, "[plugin's api load error], plugin_api_path:", plugin_api_path, ok)
        else
            if plugin_api and type(plugin_api) == "table" then
                for uri, api_methods in pairs(plugin_api) do
                    ngx.log(ngx.ERR, "load route, uri:", uri)

                    if type(api_methods) == "table" then
                        for method, func in pairs(api_methods) do
                            local m = string_lower(method)

                            if m == "get" then
                                 api_router:get(uri, func(store))
                            elseif m == "post" then
                                api_router:post(uri, func(store))
                            elseif m == "put" then
                                api_router:put(uri, func(store))
                            elseif m == "delete" then
                                api_router:delete(uri, func(store))
                            end
                        end
                    end
                end
            end
        end
    end

    return api_router
end

