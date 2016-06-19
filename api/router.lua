local lor = require("lor.index")
local ipairs = ipairs
local table_insert = table.insert

return function(config, store)
    local api_router = lor:Router()
    local stat_api = require("orange.plugins.stat.api")
    local waf_api = require("orange.plugins.waf.api")
    local rewrite_api = require("orange.plugins.rewrite.api")
    local redirect_api = require("orange.plugins.redirect.api")
    local divide_api = require("orange.plugins.divide.api")
    local monitor_api = require("orange.plugins.monitor.api")
    local orange_db = require("orange.store.orange_db")

    --- 全局信息
    -- 当前加载的插件，开启与关闭情况
    -- 每个插件的规则条数等
    api_router:get("/plugins", function(req, res, next)
        local plugins = config.plugins

        local plugin_configs = {}
        for i, v in ipairs(plugins) do
            local tmp = {
                enable =  orange_db.get(v .. ".enable"),
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
            plugin_configs[v] = tmp
        end

        res:json({
            success = true,
            data = {
                plugins = plugins,
                plugin_configs = plugin_configs
            }
        })
    end)

    
    api_router:get("/stat/status", stat_api["/stat/status"])

    api_router:get("/monitor/configs", monitor_api["/monitor/configs"].GET(store))
    api_router:post("/monitor/configs", monitor_api["/monitor/configs"].POST(store))
    api_router:delete("/monitor/configs", monitor_api["/monitor/configs"].DELETE(store))
    api_router:put("/monitor/configs", monitor_api["/monitor/configs"].PUT(store))
    api_router:post("/monitor/enable", monitor_api["/monitor/enable"].POST(store))
    api_router:get("/monitor/stat", monitor_api["/monitor/stat"].GET(store))
    api_router:get("/monitor/fetch_config", monitor_api["/monitor/fetch_config"].GET(store))
    api_router:post("/monitor/sync", monitor_api["/monitor/sync"].POST(store))


    api_router:get("/waf/configs", waf_api["/waf/configs"].GET(store))
    api_router:post("/waf/configs", waf_api["/waf/configs"].POST(store))
    api_router:delete("/waf/configs", waf_api["/waf/configs"].DELETE(store))
    api_router:put("/waf/configs", waf_api["/waf/configs"].PUT(store))
    api_router:post("/waf/enable", waf_api["/waf/enable"].POST(store))
    api_router:get("/waf/stat", waf_api["/waf/stat"].GET(store))
    api_router:get("/waf/fetch_config", waf_api["/waf/fetch_config"].GET(store))
    api_router:post("/waf/sync", waf_api["/waf/sync"].POST(store))


    api_router:get("/redirect/configs", redirect_api["/redirect/configs"].GET(store))
    api_router:post("/redirect/configs", redirect_api["/redirect/configs"].POST(store))
    api_router:delete("/redirect/configs", redirect_api["/redirect/configs"].DELETE(store))
    api_router:put("/redirect/configs", redirect_api["/redirect/configs"].PUT(store))
    api_router:post("/redirect/enable", redirect_api["/redirect/enable"].POST(store))
    api_router:get("/redirect/fetch_config", redirect_api["/redirect/fetch_config"].GET(store))
    api_router:post("/redirect/sync", redirect_api["/redirect/sync"].POST(store))


    api_router:get("/rewrite/configs", rewrite_api["/rewrite/configs"].GET(store))
    api_router:post("/rewrite/configs", rewrite_api["/rewrite/configs"].POST(store))
    api_router:delete("/rewrite/configs", rewrite_api["/rewrite/configs"].DELETE(store))
    api_router:put("/rewrite/configs", rewrite_api["/rewrite/configs"].PUT(store))
    api_router:post("/rewrite/enable", rewrite_api["/rewrite/enable"].POST(store))
    api_router:get("/rewrite/fetch_config", rewrite_api["/rewrite/fetch_config"].GET(store))
    api_router:post("/rewrite/sync", rewrite_api["/rewrite/sync"].POST(store))


    api_router:get("/divide/configs", divide_api["/divide/configs"].GET(store))
    api_router:post("/divide/configs", divide_api["/divide/configs"].POST(store))
    api_router:delete("/divide/configs", divide_api["/divide/configs"].DELETE(store))
    api_router:put("/divide/configs", divide_api["/divide/configs"].PUT(store))
    api_router:post("/divide/enable", divide_api["/divide/enable"].POST(store))
    api_router:get("/divide/fetch_config", divide_api["/divide/fetch_config"].GET(store))
    api_router:post("/divide/sync", divide_api["/divide/sync"].POST(store))
    

    return api_routerend
end

