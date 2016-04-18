local API = {}
local table_insert = table.insert
local cjson = require("cjson")
local utils = require("orange.utils.utils")

API["/divide/enable"] = {
    POST = function(store)
        return function(req, res, next)
            local enable = req.body.enable
            if enable == "1" then
                enable = true
            else
                enable = false
            end

            local current_divide_config = store:get("divide_config") or {}
            current_divide_config.enable = enable

            -- save to file
            store:set("divide_config", current_divide_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    msg = (enable == true and "开启分流功能成功" or "关闭分流功能成功")
                })
            else
                res:json({
                    success = false,
                    data = (enable == true and "开启分流功能失败" or "关闭分流功能失败")
                })
            end
        end
    end
}

API["/divide/configs"] = {
    GET = function(store)
        return function(req, res, next)
            local result = {
                success = true,
                data = store:get("divide_config") or {}
            }

            res:json(result)
        end
    end,
    PUT = function(store)
        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)
            rule.id = utils.new_id()
            rule.time = utils.now()
            -- check
            local current_divide_config = store:get("divide_config") or {rules={} }
            current_divide_config.rules = current_divide_config.rules or {}
            table_insert(current_divide_config.rules, rule)

            -- save to file
            store:set("divide_config", current_divide_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_divide_config
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
            local current_divide_config = store:get("divide_config")
            local old_rules = current_divide_config.rules
            local new_rules = {}
            for i, v in ipairs(old_rules) do
                if v.id ~= rule_id then
                    table_insert(new_rules, v)
                end
            end
            current_divide_config.rules = new_rules

            -- save to file
            store:set("divide_config", current_divide_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_divide_config
                })
            else
                current_divide_config.rules = old_rules
                res:json({
                    success = false,
                    data = current_divide_config
                })
            end
        end
    end,
    POST = function(store)
        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)
            -- check
            local current_divide_config = store:get("divide_config")
            local old_rules = current_divide_config.rules
            local new_rules = {}
            for i, v in ipairs(old_rules) do
                if v.id == rule.id then
                    rule.time = utils.now()
                    table_insert(new_rules, rule)
                else
                    table_insert(new_rules, v)
                end
            end
            current_divide_config.rules = new_rules

            -- save to file
            store:set("divide_config", current_divide_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = current_divide_config
                })
            else
                current_divide_config.rules = old_rules
                res:json({
                    success = false,
                    data = current_divide_config
                })
            end
        end
    end
}


return API