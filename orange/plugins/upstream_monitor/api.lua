--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/3/14
-- Time: 13:55
-- To change this template use File | Settings | File Templates.
--
local ipairs = ipairs
local type = type
local tostring = tostring
local string_format = string.format
local cjson = require("cjson")
local xpcall = xpcall
local traceback = debug.traceback
local orange_db = require("orange.store.orange_db")
local BaseAPI = require("orange.plugins.base_api")

local BaseAPI = require("orange.plugins.base_api")

local API = BaseAPI:new("upstream-monitor", 2)
local common_api = require("orange.plugins.common_api")
API:merge_apis(common_api("upstream_monitor"))

API:get("/upstream_monitor/configs", function(store)
    return function(req, res, next)
        ngx.log(ngx.ERR,"--------------------------------------------------------------good")

--        local conf = req.body.conf
--        local success, data = false, {}
--
--        -- 插入或更新到mysql
--        local update_result = store:update({
--            sql = "replace into meta SET `key`=?, `value`=?",
--            params = { "upstream_monitor.conf", 1 }
--        })
--
--        if update_result then
--            local result, err, forcible = orange_db.set("kvstore.conf", conf)
--            success = result
--            if success then
            local data ={}
            data.conf = {1,2,3,4}
            data.enable = 1
--            end
--        else
--            success = false
--        end


        data.conf = {1,2,3,4}
        data.enable = 1
        res:json({
            success = true,
            data = data
        })
    end
end)
return API


