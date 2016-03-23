local API = {}
local table_insert = table.insert
local cjson = require("cjson")
local utils = require("orange.utils.utils")

API["/waf/enable"] = {
    POST = function(store)
        return function(req, res, next)
            local enable = req.body.enable
            if enable == "1" then
                enable = true
            else
                enable = false
            end

            local current_waf_config = store:get("waf_config")
            current_waf_config.enable = enable

            -- save to file
            store:set("waf_config", current_waf_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    msg = (enable == true and "开启防火墙成功" or "关闭防火墙成功")
                })
            else
                res:json({
                    success = false,
                    data = (enable == true and "开启防火墙失败" or "关闭防火墙失败")
                })
            end
        end
    end
}

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
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_waf_config
                })
            else
                res:json({
                    success = false
                })
            end
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
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_waf_config
                })
            else
                current_waf_config.access_rules = old_rules
                res:json({
                    success = false,
                    data = current_waf_config
                })
            end
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
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_waf_config
                })
            else
                current_waf_config.access_rules = old_rules
                res:json({
                    success = false,
                    data = current_waf_config
                })
            end
        end
    end
}


return API