--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/3/14
-- Time: 13:55
-- To change this template use File | Settings | File Templates.
--

local BaseAPI = require("orange.plugins.base_api")

local API = BaseAPI:new("upstream-monitor", 2)
local common_api = require("orange.plugins.common_api")
local shared_config = require("resty.upstream.shared_config")
local hc = require "resty.upstream.healthcheck"


API:merge_apis(common_api("upstream_monitor"))

API:get("/upstream_monitor/configs", function(store)
    return function(req, res, next)
        ngx.log(ngx.ERR,"--------------------------------------------------------------good")
            local data ={}

            data.conf = shared_config:get()
            data.enable = 1
            data.upstream_status= hc:status_page()

            res:json({
                success = true,
                data = data,
            })
    end
end)

API:post("/upstream_monitor/configs",function(store)
    return function(req, res, next)
        local cjson = require('cjson')

        ngx.log(ngx.ERR,cjson.encode(req.body))
        return
        hc.check_and_set_config(req.body)

    end
end)

return API


