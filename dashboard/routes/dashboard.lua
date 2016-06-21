local lor = require("lor.index")
local ipairs = ipairs
local table_insert = table.insert

return function(config, store)
    local dashboard_router = lor:Router()
    local stat_api = require("orange.dashboard.routes.stat_api")
    local waf_api = require("orange.dashboard.routes.waf_api")
    local rewrite_api = require("orange.dashboard.routes.rewrite_api")
    local redirect_api = require("orange.dashboard.routes.redirect_api")
    local divide_api = require("orange.dashboard.routes.divide_api")
    local monitor_api = require("orange.dashboard.routes.monitor_api")
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


    dashboard_router:get("/waf", function(req, res, next)
        res:render("waf")
    end)

    dashboard_router:get("/divide", function(req, res, next)
        res:render("divide")
    end)

    dashboard_router:get("/help", function(req, res, next)
        res:render("help")
    end)


    dashboard_router:get("/stat/status", stat_api["/stat/status"])

    dashboard_router:get("/monitor/configs", monitor_api["/monitor/configs"].GET(store))
    dashboard_router:post("/monitor/configs", monitor_api["/monitor/configs"].POST(store))
    dashboard_router:delete("/monitor/configs", monitor_api["/monitor/configs"].DELETE(store))
    dashboard_router:put("/monitor/configs", monitor_api["/monitor/configs"].PUT(store))
    dashboard_router:post("/monitor/enable", monitor_api["/monitor/enable"].POST(store))
    dashboard_router:get("/monitor/stat", monitor_api["/monitor/stat"].GET(store))
    dashboard_router:get("/monitor/fetch_config", monitor_api["/monitor/fetch_config"].GET(store))
    dashboard_router:post("/monitor/sync", monitor_api["/monitor/sync"].POST(store))


    dashboard_router:get("/waf/configs", waf_api["/waf/configs"].GET(store))
    dashboard_router:post("/waf/configs", waf_api["/waf/configs"].POST(store))
    dashboard_router:delete("/waf/configs", waf_api["/waf/configs"].DELETE(store))
    dashboard_router:put("/waf/configs", waf_api["/waf/configs"].PUT(store))
    dashboard_router:post("/waf/enable", waf_api["/waf/enable"].POST(store))
    dashboard_router:get("/waf/stat", waf_api["/waf/stat"].GET(store))
    dashboard_router:get("/waf/fetch_config", waf_api["/waf/fetch_config"].GET(store))
    dashboard_router:post("/waf/sync", waf_api["/waf/sync"].POST(store))


    dashboard_router:get("/redirect/configs", redirect_api["/redirect/configs"].GET(store))
    dashboard_router:post("/redirect/configs", redirect_api["/redirect/configs"].POST(store))
    dashboard_router:delete("/redirect/configs", redirect_api["/redirect/configs"].DELETE(store))
    dashboard_router:put("/redirect/configs", redirect_api["/redirect/configs"].PUT(store))
    dashboard_router:post("/redirect/enable", redirect_api["/redirect/enable"].POST(store))
    dashboard_router:get("/redirect/fetch_config", redirect_api["/redirect/fetch_config"].GET(store))
    dashboard_router:post("/redirect/sync", redirect_api["/redirect/sync"].POST(store))


    dashboard_router:get("/rewrite/configs", rewrite_api["/rewrite/configs"].GET(store))
    dashboard_router:post("/rewrite/configs", rewrite_api["/rewrite/configs"].POST(store))
    dashboard_router:delete("/rewrite/configs", rewrite_api["/rewrite/configs"].DELETE(store))
    dashboard_router:put("/rewrite/configs", rewrite_api["/rewrite/configs"].PUT(store))
    dashboard_router:post("/rewrite/enable", rewrite_api["/rewrite/enable"].POST(store))
    dashboard_router:get("/rewrite/fetch_config", rewrite_api["/rewrite/fetch_config"].GET(store))
    dashboard_router:post("/rewrite/sync", rewrite_api["/rewrite/sync"].POST(store))


    dashboard_router:get("/divide/configs", divide_api["/divide/configs"].GET(store))
    dashboard_router:post("/divide/configs", divide_api["/divide/configs"].POST(store))
    dashboard_router:delete("/divide/configs", divide_api["/divide/configs"].DELETE(store))
    dashboard_router:put("/divide/configs", divide_api["/divide/configs"].PUT(store))
    dashboard_router:post("/divide/enable", divide_api["/divide/enable"].POST(store))
    dashboard_router:get("/divide/fetch_config", divide_api["/divide/fetch_config"].GET(store))
    dashboard_router:post("/divide/sync", divide_api["/divide/sync"].POST(store))
    

    return dashboard_router
end


