local API = {}
local table_insert = table.insert
local cjson = require("cjson")
local utils = require("orange.utils.utils")

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

    PUT = function(store)
        return function(req, res, next)
        	local rule = req.body.rule
        	rule = cjson.decode(rule)
            rule.id = utils.new_id()
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
    end,

    DELETE = function(store)
        return function(req, res, next)
            local rule_id = tostring(req.body.rule_id)
            if not rule_id or rule_id == "" then
                return res:json({
                    success = false,
                    msg = "error param: rule id shoule not be null."
                })
            end

            -- check
            local current_waf_config = store:get("waf_config")
            local old_rules = current_waf_config.access_rules
            local new_rules = {}
            for i, v in ipairs(old_rules) do 
                if v.id ~= rule_id then
                    table_insert(new_rules, v)
                end
            end
            current_waf_config.access_rules = new_rules

            -- save to file
            store:set("waf_config", current_waf_config)
            store:store()

            local result = {
                success = true,
                data = current_waf_config
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
            local old_rules = current_waf_config.access_rules
            local new_rules = {}
            for i, v in ipairs(old_rules) do 
                if v.id == rule.id then
                    table_insert(new_rules, rule)
                else
                    table_insert(new_rules, v)
                end
            end
            current_waf_config.access_rules = new_rules

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