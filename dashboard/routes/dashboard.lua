local lor = require("lor.index")
local store = require("orange.store.file_store")({
    file_path = "./orange.conf"
})

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

dashboard_router:get("/status", stat_api["/status"])
dashboard_router:get("/waf/configs", waf_api["/waf/configs"].GET(store))
dashboard_router:get("/rewrite/configs", rewrite_api["/rewrite/configs"].GET(store))
dashboard_router:get("/redirect/configs", redirect_api["/redirect/configs"].GET(store))

dashboard_router:post("/waf/configs", waf_api["/waf/configs"].POST(store))


return dashboard_router