local API = {}
local table_insert = table.insert
local ipairs = ipairs
local type = type
local tostring = tostring
local cjson = require("cjson")
local utils = require("orange.utils.utils")
local stat = require("orange.plugins.monitor.stat")
local orange_db = require("orange.store.orange_db")


API["/monitor/enable"] = {
    POST = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local enable = req.body.enable
            if enable == "1" then enable = true else enable = false end

            local result = false
            if store_type == "file" then
                local monitor_config = store:get("monitor_config") or {}
                monitor_config.enable = enable
                store:set("monitor_config", monitor_config)
                result = store:store()
            elseif store_type == "mysql" then
                local monitor_enable = "0"
                if enable then monitor_enable = "1" end
                local update_result = store:update({
                    sql = "replace into meta SET `key`=?, `value`=?",
                    params = { "monitor.enable", monitor_enable }
                })

                if update_result then
                    local success, err, forcible = orange_db.set("monitor.enable", enable)
                    result = success
                else
                    result = false
                end
            end

            if result then
                res:json({
                    success = true,
                    msg = (enable == true and "开启自定义监控成功" or "关闭自定义监控成功")
                })
            else
                res:json({
                    success = false,
                    data = (enable == true and "开启自定义监控失败" or "关闭自定义监控失败")
                })
            end
        end
    end
}

API["/monitor/stat"] = {
    GET = function(store)
        return function(req, res, next)
            local rule_id = req.query.rule_id
            local statistics = stat.get(rule_id)

            local result = {
                success = true,
                data = statistics
            }
            res:json(result)
        end
    end,
}

API["/monitor/fetch_config"] = {
    -- fetch data from db
    GET = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local success, data = false, {}
            if store_type == "file" then
                success = true
                data = store:get("divide_config") or { enable = false, rules = {} }
            elseif store_type == "mysql" then
                -- 查找enable
                local enable, err1 = store:query({
                    sql = "select `value` from meta where `key`=?",
                    params = { "monitor.enable" }
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
                    sql = "select `value` from monitor order by id asc"
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
            end

            res:json({
                success = success,
                data = data
            })
        end
    end,
}

API["/monitor/sync"] = {
    -- update the local cache to data stored in db
    POST = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local success, data = false, {}
            if store_type == "file" then
                success = true
            elseif store_type == "mysql" then
                -- 查找enable
                local enable, err1 = store:query({
                    sql = "select `value` from meta where `key`=?",
                    params = { "monitor.enable" }
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
                    sql = "select `value` from monitor order by id asc"
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


                local ss, err3, forcible = orange_db.set("monitor.enable", data.enable)
                if not ss or err3 then
                    return res:json({
                        success = false,
                        msg = "update local enable error"
                    })
                end
                ss, err3, forcible = orange_db.set_json("monitor.rules", data.rules)
                if not ss or err3 then
                    return res:json({
                        success = false,
                        msg = "update local rules error"
                    })
                end

                success = true
            end

            res:json({
                success = success
            })
        end
    end,
}


API["/monitor/configs"] = {
    GET = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local success, data = false, {}
            if store_type == "file" then
                success = true
                data = store:get("monitor_config") or { enable = false, rules = {} }
            elseif store_type == "mysql" then
                data.enable = orange_db.get("monitor.enable")
                data.rules = orange_db.get_json("monitor.rules")
                success = true
            end

            res:json({
                success = success,
                data = data
            })
        end
    end,
    PUT = function(store) -- new
    local store_type = store.store_type

    return function(req, res, next)
        local rule = req.body.rule
        rule = cjson.decode(rule)
        rule.id = utils.new_id()
        rule.time = utils.now()

        local success, data = false, {}
        if store_type == "file" then
            -- check
            local monitor_config = store:get("monitor_config") or { enable = false, rules = {} }
            monitor_config.rules = monitor_config.rules or {}
            table_insert(monitor_config.rules, rule)

            -- save to file
            store:set("monitor_config", monitor_config)
            success = store:store()
            data = monitor_config
        elseif store_type == "mysql" then
            -- 插入到mysql
            local insert_result = store:insert({
                sql = "insert into monitor(`key`, `value`) values(?,?)",
                params = { rule.id, cjson.encode(rule) }
            })

            -- 插入成功，则更新本地缓存
            if insert_result then
                local monitor_rules = orange_db.get_json("monitor.rules") or {}
                table_insert(monitor_rules, rule)
                local s, err, forcible = orange_db.set_json("monitor.rules", monitor_rules)
                if s then
                    success = true
                    data.rules = monitor_rules
                    data.enable = orange_db.get("monitor.enable")
                else
                    ngx.log(ngx.ERR, "save monitor rules locally error: ", err)
                end
            else
                success = false
            end
        end

        res:json({
            success = success,
            data = data
        })
    end
    end,
    DELETE = function(store)
        local store_type = store.store_type
        return function(req, res, next)
            local rule_id = tostring(req.body.rule_id)
            if not rule_id or rule_id == "" then
                return res:json({
                    success = false,
                    msg = "error param: rule id shoule not be null."
                })
            end


            if store_type == "file" then
                -- check
                local monitor_config = store:get("monitor_config")
                local old_rules = monitor_config.rules
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id ~= rule_id then
                        table_insert(new_rules, v)
                    end
                end
                monitor_config.rules = new_rules

                -- save to file
                store:set("monitor_config", monitor_config)
                local store_result = store:store()

                if store_result == true then
                    res:json({
                        success = true,
                        data = monitor_config
                    })
                else
                    monitor_config.rules = old_rules
                    res:json({
                        success = false,
                        data = monitor_config
                    })
                end
            elseif store_type == "mysql" then
                local delete_result = store:delete({
                    sql = "delete from monitor where `key`=?",
                    params ={rule_id}
                })

                if delete_result then
                    local old_rules = orange_db.get_json("monitor.rules") or {}
                    local new_rules = {}
                    for i, v in ipairs(old_rules) do
                        if v.id ~= rule_id then
                            table_insert(new_rules, v)
                        end
                    end
                    local success, err, forcible = orange_db.set_json("monitor.rules", new_rules)
                    if err or forcible then
                        ngx.log(ngx.ERR, "update local rules error when deleting:", err, ":", forcible)
                        return res:json({
                            success = false,
                            msg = "update local rules error when deleting"
                        })
                    end

                    res:json({
                        success = success,
                        data = {
                            rules = new_rules,
                            enable = orange_db.get("monitor.enable")
                        }
                    })
                else
                    res:json({
                        success = false,
                        msg = "delete rule from db error"
                    })
                end
            end
        end
    end,

    POST = function(store) -- modify
    local store_type = store.store_type
    return function(req, res, next)
        local rule = req.body.rule
        rule = cjson.decode(rule)


        if store_type == "file" then
            -- check
            local monitor_config = store:get("monitor_config")
            local old_rules = monitor_config.rules
            local new_rules = {}
            for i, v in ipairs(old_rules) do
                if v.id == rule.id then
                    rule.time = utils.now()
                    table_insert(new_rules, rule)
                else
                    table_insert(new_rules, v)
                end
            end
            monitor_config.rules = new_rules

            -- save to file
            store:set("monitor_config", monitor_config)
            local store_result = store:store()

            if store_result == true then
                res:json({
                    success = true,
                    data = monitor_config
                })
            else
                monitor_config.rules = old_rules
                res:json({
                    success = false,
                    data = monitor_config
                })
            end
        elseif store_type == "mysql" then
            local update_result = store:delete({
                sql = "update monitor set `value`=? where `key`=?",
                params ={cjson.encode(rule), rule.id}
            })

            if update_result then
                local old_rules = orange_db.get_json("monitor.rules") or {}
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id == rule.id then
                        rule.time = utils.now()
                        table_insert(new_rules, rule)
                    else
                        table_insert(new_rules, v)
                    end
                end

                local success, err, forcible = orange_db.set_json("monitor.rules", new_rules)
                if err or forcible then
                    ngx.log(ngx.ERR, "update local rules error when modifing:", err, ":", forcible)
                    return res:json({
                        success = false,
                        msg = "update local rules error when modifing"
                    })
                end

                res:json({
                    success = success,
                    data = {
                        rules = new_rules,
                        enable = orange_db.get("monitor.enable")
                    }
                })

            else
                res:json({
                    success = false,
                    msg = "update rule to db error"
                })
            end
        end
    end
    end
}

return API