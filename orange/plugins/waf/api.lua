local API = {}
local table_insert = table.insert
local cjson = require("cjson")

API["/waf/configs"] = {
    GET = function(store)
        return function(req, res, next)
            local result = {
                success = true,
                data = store:get_waf_config()
            }

            res:json(result)
        end
    end,

    POST = function(store)
        return function(req, res, next)
        	local rule = req.body.rule
        	rule = cjson.decode(rule)
        	-- check
        	local current_waf_config = store:get("waf_config")
        	table_insert(current_waf_config.access_rules, rule)
        	-- save to file
        	store:set("waf_config", current_waf_config)
        	store:store()

            local result = {
                success = true,
                data = current_waf_config
            }

            res:json(result)
        end
    end
}


return API