local lor = require("lor.index")
local ipairs = ipairs
local table_insert = table.insert

return function(config, store)
	local dashboard_router = lor:Router()
	local stat_api = require("orange.plugins.stat.api")
	local waf_api = require("orange.plugins.waf.api")
	local rewrite_api = require("orange.plugins.rewrite.api")
	local redirect_api = require("orange.plugins.redirect.api")
    local divide_api = require("orange.plugins.divide.api")
    local url_monitor_api = require("orange.plugins.url_monitor.api")

	dashboard_router:get("/", function(req, res, next)
		--- 全局信息
        -- 当前加载的插件，开启与关闭情况
        -- 每个插件的规则条数等
        local data = {}
        local plugins = config.plugins
        local store_data = store:get_all()
        data.plugins = plugins
        data.store_type = config.store

        local plugin_configs = {}
        for i, v in ipairs(plugins) do
            local tmp = {
                enable = nil,
                name = v,
                active_rule_count = 0,
                inactive_rule_count = 0
            }
            local plugin_config = store_data[v .. "_config"]
            if plugin_config then
                tmp.enable = plugin_config.enable
                local rules_key = "rules"
                local plugin_rules = plugin_config[rules_key]
                if plugin_rules then
                    for j, r in ipairs(plugin_rules) do
                        if r.enable == true then
                            tmp.active_rule_count = tmp.active_rule_count + 1
                        else
                            tmp.inactive_rule_count = tmp.inactive_rule_count + 1
                        end
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

    dashboard_router:get("/url_monitor", function(req, res, next)
        res:render("url_monitor")
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

    dashboard_router:get("/url_monitor/configs", url_monitor_api["/url_monitor/configs"].GET(store))
    dashboard_router:post("/url_monitor/configs", url_monitor_api["/url_monitor/configs"].POST(store))
    dashboard_router:delete("/url_monitor/configs", url_monitor_api["/url_monitor/configs"].DELETE(store))
    dashboard_router:put("/url_monitor/configs", url_monitor_api["/url_monitor/configs"].PUT(store))
    dashboard_router:post("/url_monitor/enable", url_monitor_api["/url_monitor/enable"].POST(store))
    dashboard_router:get("/url_monitor/stat", url_monitor_api["/url_monitor/stat"].GET(store))


	dashboard_router:get("/waf/configs", waf_api["/waf/configs"].GET(store))
	dashboard_router:post("/waf/configs", waf_api["/waf/configs"].POST(store))
	dashboard_router:delete("/waf/configs", waf_api["/waf/configs"].DELETE(store))
	dashboard_router:put("/waf/configs", waf_api["/waf/configs"].PUT(store))
	dashboard_router:post("/waf/enable", waf_api["/waf/enable"].POST(store))
    dashboard_router:get("/waf/stat", waf_api["/waf/stat"].GET(store))

	dashboard_router:get("/redirect/configs", redirect_api["/redirect/configs"].GET(store))
	dashboard_router:post("/redirect/configs", redirect_api["/redirect/configs"].POST(store))
	dashboard_router:delete("/redirect/configs", redirect_api["/redirect/configs"].DELETE(store))
	dashboard_router:put("/redirect/configs", redirect_api["/redirect/configs"].PUT(store))
	dashboard_router:post("/redirect/enable", redirect_api["/redirect/enable"].POST(store))

	dashboard_router:get("/rewrite/configs", rewrite_api["/rewrite/configs"].GET(store))
	dashboard_router:post("/rewrite/configs", rewrite_api["/rewrite/configs"].POST(store))
	dashboard_router:delete("/rewrite/configs", rewrite_api["/rewrite/configs"].DELETE(store))
	dashboard_router:put("/rewrite/configs", rewrite_api["/rewrite/configs"].PUT(store))
	dashboard_router:post("/rewrite/enable", rewrite_api["/rewrite/enable"].POST(store))

    dashboard_router:get("/divide/configs", divide_api["/divide/configs"].GET(store))
    dashboard_router:post("/divide/configs", divide_api["/divide/configs"].POST(store))
    dashboard_router:delete("/divide/configs", divide_api["/divide/configs"].DELETE(store))
    dashboard_router:put("/divide/configs", divide_api["/divide/configs"].PUT(store))
    dashboard_router:post("/divide/enable", divide_api["/divide/enable"].POST(store))

	return dashboard_router
end


