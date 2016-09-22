local API = {}
local table_insert = table.insert
local ipairs = ipairs
local type = type
local tostring = tostring
local cjson = require("cjson")
local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")

API["/divide/enable"] = {
    POST = function(store)
        return function(req, res, next)
            local enable = req.body.enable
            if enable == "1" then enable = true else enable = false end

            local result = false
    
            local divide_enable = "0"
            if enable then divide_enable = "1" end
            local update_result = store:update({
                sql = "replace into meta SET `key`=?, `value`=?",
                params = { "divide.enable", divide_enable }
            })

            if update_result then
                local success, err, forcible = orange_db.set("divide.enable", enable)
                result = success
            else
                result = false
            end
         
            if result then
                res:json({
                    success = true,
                    msg = (enable == true and "开启分流功能成功" or "关闭分流功能成功")
                })
            else
                res:json({
                    success = false,
                    msg = (enable == true and "开启分流功能失败" or "关闭分流功能失败")
                })
            end
        end
    end
}

API["/divide/fetch_config"] = {
    -- fetch data from db
    GET = function(store)
        return function(req, res, next)
            local success, data = false, {enable=false}
            
            -- 查找enable
            local enable, err1 = store:query({
                sql = "select `value` from meta where `key`=?",
                params = { "divide.enable" }
            })

            if err1 then
                return res:json({
                    success = false,
                    msg = "get enable error"
                })
            end

            if enable and type(enable) == "table" and #enable == 1 and enable[1].value == "1" then
                data.enable = true
            else
                data.enable = false
            end

            -- 查找rules
            local rules, err2 = store:query({
                sql = "select `value` from divide order by id asc"
            })
            if err2 then
                return res:json({
                    success = false,
                    msg = "get rules error"
                })
            end

            if rules and type(rules) == "table" and #rules > 0 then
                local format_rules = {}
                for i, v in ipairs(rules) do
                    table_insert(format_rules, cjson.decode(v.value))
                end
                data.rules = format_rules
                success = true
            else
                success = true
                data.rules = {}
            end

            res:json({
                success = success,
                data = data
            })
        end
    end,
}

API["/divide/sync"] = {
    -- update the local cache to data stored in db
    POST = function(store)
        return function(req, res, next)
            local success, data = false, {}
            
            -- 查找enable
            local enable, err1 = store:query({
                sql = "select `value` from meta where `key`=?",
                params = { "divide.enable" }
            })

            if err1 then
                return res:json({
                    success = false,
                    msg = "get enable error"
                })
            end

            if enable and type(enable) == "table" and #enable == 1 and enable[1].value == "1" then
                data.enable = true
            else
                data.enable = false
            end

            -- 查找rules
            local rules, err2 = store:query({
                sql = "select `value` from divide order by id asc"
            })
            if err2 then
                return res:json({
                    success = false,
                    msg = "get rules error"
                })
            end

            if rules and type(rules) == "table" and #rules > 0 then
                local format_rules = {}
                for i, v in ipairs(rules) do
                    table_insert(format_rules, cjson.decode(v.value))
                end
                data.rules = format_rules
            else
                data.rules = {}
            end


            local ss, err3, forcible = orange_db.set("divide.enable", data.enable)
            if not ss or err3 then
                return res:json({
                    success = false,
                    msg = "update local enable error"
                })
            end
            ss, err3, forcible = orange_db.set_json("divide.rules", data.rules)
            if not ss or err3 then
                return res:json({
                    success = false,
                    msg = "update local rules error"
                })
            end

            res:json({
                success = true,
                msg = "ok"
            })
        end
    end,
}

API["/divide/configs"] = {
    GET = function(store)
        return function(req, res, next)
            local success, data = false, {}
            data.enable = orange_db.get("divide.enable") or false
            data.rules = orange_db.get_json("divide.rules") or {}

            res:json({
                success = true,
                data = data
            })
        end
    end,

    -- new
    POST = function(store)
        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)
            rule.id = utils.new_id()
            rule.time = utils.now()

            local success = false
            
            -- 插入到mysql
            local insert_result = store:insert({
                sql = "insert into divide(`key`, `value`, `op_time`) values(?,?,?)",
                params = { rule.id, cjson.encode(rule), rule.time }
            })

            -- 插入成功，则更新本地缓存
            if insert_result then
                local divide_rules = orange_db.get_json("divide.rules") or {}
                table_insert(divide_rules, rule)
                local s, err, forcible = orange_db.set_json("divide.rules", divide_rules)
                if s then
                    success = true
                else
                    ngx.log(ngx.ERR, "save divide rules locally error: ", err)
                end
            else
                success = false
            end

            res:json({
                success = success,
                msg = success and "ok" or "new rule failed"
            })
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


            local delete_result = store:delete({
                sql = "delete from divide where `key`=?",
                params = { rule_id }
            })

            if delete_result then
                local old_rules = orange_db.get_json("divide.rules") or {}
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id ~= rule_id then
                        table_insert(new_rules, v)
                    end
                end
                local success, err, forcible = orange_db.set_json("divide.rules", new_rules)
                if err or forcible then
                    ngx.log(ngx.ERR, "update local rules error when deleting:", err, ":", forcible)
                    return res:json({
                        success = false,
                        msg = "update local rules error when deleting"
                    })
                end

                res:json({
                    success = success,
                    msg = success and "ok" or "new rule failed"
                })
            else
                res:json({
                    success = false,
                    msg = "delete rule from db error"
                })
            end
            
        end
    end,

    -- modify
    PUT = function(store)
        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)
            rule.time = utils.now()
        
            local update_result = store:delete({
                sql = "update divide set `value`=?, `op_time`=? where `key`=?",
                params = { cjson.encode(rule), rule.time, rule.id }
            })

            if update_result then
                local old_rules = orange_db.get_json("divide.rules") or {}
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id == rule.id then
                        rule.time = utils.now()
                        table_insert(new_rules, rule)
                    else
                        table_insert(new_rules, v)
                    end
                end

                local success, err, forcible = orange_db.set_json("divide.rules", new_rules)
                if err or forcible then
                    ngx.log(ngx.ERR, "update local rules error when modifing:", err, ":", forcible)
                    return res:json({
                        success = false,
                        msg = "update local rules error when modifing"
                    })
                end

                res:json({
                    success = success,
                    msg = success and "ok" or "new rule failed"
                })

            else
                res:json({
                    success = false,
                    msg = "update rule to db error"
                })
            end
        end
    end
}


return API
