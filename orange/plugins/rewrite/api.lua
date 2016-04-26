local API = {}
local table_insert = table.insert
local ipairs = ipairs
local type = type
local tostring = tostring
local cjson = require("cjson")
local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")

API["/rewrite/enable"] = {
    POST = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local enable = req.body.enable
            if enable == "1" then enable = true else enable = false end

            local result = false
            if store_type == "file" then
                local rewrite_config = store:get("rewrite_config") or {}
                rewrite_config.enable = enable
                store:set("rewrite_config", rewrite_config)
                result = store:store()
            elseif store_type == "mysql" then
                local rewrite_enable = "0"
                if enable then rewrite_enable = "1" end
                local update_result = store:update({
                    sql = "replace into meta SET `key`=?, `value`=?",
                    params = { "rewrite.enable", rewrite_enable }
                })

                if update_result then
                    local success, err, forcible = orange_db.set("rewrite.enable", enable)
                    result = success
                else
                    result = false
                end
            end

            if result then
                res:json({
                    success = true,
                    msg = (enable == true and "开启rewrite成功" or "关闭rewrite成功")
                })
            else
                res:json({
                    success = false,
                    data = (enable == true and "开启rewrite失败" or "关闭rewrite失败")
                })
            end
        end
    end
}

API["/rewrite/fetch_config"] = {
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
                    params = { "rewrite.enable" }
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
                    sql = "select `value` from rewrite order by id asc"
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

API["/rewrite/sync"] = {
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
                    params = { "rewrite.enable" }
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
                    sql = "select `value` from rewrite order by id asc"
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


                local ss, err3, forcible = orange_db.set("rewrite.enable", data.enable)
                if not ss or err3 then
                    return res:json({
                        success = false,
                        msg = "update local enable error"
                    })
                end
                ss, err3, forcible = orange_db.set_json("rewrite.rules", data.rules)
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

API["/rewrite/configs"] = {
    GET = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local success, data = false, {}
            if store_type == "file" then
                success = true
                data = store:get("rewrite_config") or { enable = false, rules = {} }
            elseif store_type == "mysql" then
                data.enable = orange_db.get("rewrite.enable")
                data.rules = orange_db.get_json("rewrite.rules")
                success = true
            end

            res:json({
                success = success,
                data = data
            })
        end
    end,

    -- new
    PUT = function(store)
        local store_type = store.store_type

        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)
            rule.id = utils.new_id()
            rule.time = utils.now()

            local success, data = false, {}
            if store_type == "file" then
                -- check
                local rewrite_config = store:get("rewrite_config") or { enable = false, rules = {} }
                rewrite_config.rules = rewrite_config.rules or {}
                table_insert(rewrite_config.rules, rule)

                -- save to file
                store:set("rewrite_config", rewrite_config)
                success = store:store()
                data = rewrite_config
            elseif store_type == "mysql" then
                -- 插入到mysql
                local insert_result = store:insert({
                    sql = "insert into rewrite(`key`, `value`) values(?,?)",
                    params = { rule.id, cjson.encode(rule) }
                })

                -- 插入成功，则更新本地缓存
                if insert_result then
                    local rewrite_rules = orange_db.get_json("rewrite.rules") or {}
                    table_insert(rewrite_rules, rule)
                    local s, err, forcible = orange_db.set_json("rewrite.rules", rewrite_rules)
                    if s then
                        success = true
                        data.rules = rewrite_rules
                        data.enable = orange_db.get("rewrite.enable")
                    else
                        ngx.log(ngx.ERR, "save rewrite rules locally error: ", err)
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
                local rewrite_config = store:get("rewrite_config")
                local old_rules = rewrite_config.rules
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id ~= rule_id then
                        table_insert(new_rules, v)
                    end
                end
                rewrite_config.rules = new_rules

                -- save to file
                store:set("rewrite_config", rewrite_config)
                local store_result = store:store()

                if store_result == true then
                    res:json({
                        success = true,
                        data = rewrite_config
                    })
                else
                    rewrite_config.rules = old_rules
                    res:json({
                        success = false,
                        data = rewrite_config
                    })
                end
            elseif store_type == "mysql" then
                local delete_result = store:delete({
                    sql = "delete from rewrite where `key`=?",
                    params = { rule_id }
                })

                if delete_result then
                    local old_rules = orange_db.get_json("rewrite.rules") or {}
                    local new_rules = {}
                    for i, v in ipairs(old_rules) do
                        if v.id ~= rule_id then
                            table_insert(new_rules, v)
                        end
                    end
                    local success, err, forcible = orange_db.set_json("rewrite.rules", new_rules)
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
                            enable = orange_db.get("rewrite.enable")
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
    -- modify
    POST = function(store)
        local store_type = store.store_type
        return function(req, res, next)
            local rule = req.body.rule
            rule = cjson.decode(rule)


            if store_type == "file" then
                -- check
                local rewrite_config = store:get("rewrite_config")
                local old_rules = rewrite_config.rules
                local new_rules = {}
                for i, v in ipairs(old_rules) do
                    if v.id == rule.id then
                        rule.time = utils.now()
                        table_insert(new_rules, rule)
                    else
                        table_insert(new_rules, v)
                    end
                end
                rewrite_config.rules = new_rules

                -- save to file
                store:set("rewrite_config", rewrite_config)
                local store_result = store:store()

                if store_result == true then
                    res:json({
                        success = true,
                        data = rewrite_config
                    })
                else
                    rewrite_config.rules = old_rules
                    res:json({
                        success = false,
                        data = rewrite_config
                    })
                end
            elseif store_type == "mysql" then
                local update_result = store:delete({
                    sql = "update rewrite set `value`=? where `key`=?",
                    params = { cjson.encode(rule), rule.id }
                })

                if update_result then
                    local old_rules = orange_db.get_json("rewrite.rules") or {}
                    local new_rules = {}
                    for i, v in ipairs(old_rules) do
                        if v.id == rule.id then
                            rule.time = utils.now()
                            table_insert(new_rules, rule)
                        else
                            table_insert(new_rules, v)
                        end
                    end

                    local success, err, forcible = orange_db.set_json("rewrite.rules", new_rules)
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
                            enable = orange_db.get("rewrite.enable")
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