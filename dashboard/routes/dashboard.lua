local lor = require("lor.index")

return function(store)
	local dashboard_router = lor:Router()
	local stat_api = require("orange.plugins.stat.api")
	local waf_api = require("orange.plugins.waf.api")
	local rewrite_api = require("orange.plugins.rewrite.api")
	local redirect_api = require("orange.plugins.redirect.api")

	dashboard_router:get("/", function(req, res, next)
		res:render("status")
	end)

	dashboard_router:get("/waf", function(req, res, next)
		res:render("waf")
	end)

	dashboard_router:get("/rewrite", function(req, res, next)
	    res:render("rewrite")
	end)

	dashboard_router:get("/redirect", function(req, res, next)
	    res:render("redirect")
	end)

	dashboard_router:get("/help", function(req, res, next)
		res:render("help")
	end)


	dashboard_router:get("/stat/status", stat_api["/stat/status"])


	dashboard_router:get("/waf/configs", waf_api["/waf/configs"].GET(store))
	dashboard_router:post("/waf/configs", waf_api["/waf/configs"].POST(store))
	dashboard_router:delete("/waf/configs", waf_api["/waf/configs"].DELETE(store))
	dashboard_router:put("/waf/configs", waf_api["/waf/configs"].PUT(store))
	dashboard_router:post("/waf/enable", waf_api["/waf/enable"].POST(store))

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

	return dashboard_router
end


