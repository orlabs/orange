local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local table_concat = table.concat
local cjson = require("cjson")
local orange_db = require("orange.store.orange_db")
local BaseAPI = require("orange.plugins.base_api")
local utils = require("orange.utils.utils")

local function delete_rules_of_selector(store, rule_ids)
    if not rule_ids or rule_ids == "" or type(rule_ids) ~= "string" then 
        return true
    end

    local delete_result = store:delete({
        sql = "delete from redirect where `key` in (" .. rule_ids .. ") and `type`=?",
        params = { "rule" }
    })
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete rules of selector err, ", rule_ids)
        return false
    end
end

local function delete_selector(store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then 
        return true
    end

    local delete_result = store:delete({
        sql = "delete from redirect where `key` = ? and `type` = ?",
        params = { selector_id, "selector" }
    })
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete selector err, ", selector_id)
        return false
    end
end

local function get_selector(store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then 
        return nil
    end

    local selector, err = store:query({
        sql = "select * from redirect where `key` = ? and `type` = ? limit 1",
        params = { selector_id, "selector" }
    })

    if not err and selector and type(selector) == "table" and #selector > 0 then
        return selector[1]
    end

    return nil
end

local function get_meta(store)
    local meta, err = store:query({
        sql = "select * from redirect where `type` = ? limit 1",
        params = {"meta"}
    })

    if not err and meta and type(meta) == "table" and #meta > 0 then
        return meta[1]
    else
        ngx.log(ngx.ERR, "[FATAL ERROR]meta not found while it must exist.")
        return nil
    end
end

local function update_meta(store, meta)
    if not meta or type(meta) ~= "table" then 
        return false
    end

    local meta_json_str = utils.json_encode(meta)
    if not meta_json_str then
        ngx.log(ngx.ERR, "encode error: meta to save is not json format.")
        return false
    end

    local result = store:update({
        sql = "update redirect set `value` = ? where `type` = ?",
        params = {meta_json_str, "meta"}
    })

    return result
end

local API = BaseAPI:new("redirect-api", 2)

API:post("/redirect/enable", function(store)
    return function(req, res, next)
        local enable = req.body.enable
        if enable == "1" then enable = true else enable = false end

        local result = false
        
        local redirect_enable = "0"
        if enable then redirect_enable = "1" end
        local update_result = store:update({
            sql = "replace into meta SET `key`=?, `value`=?",
            params = { "redirect.enable", redirect_enable }
        })

        if update_result then
            local success, err, forcible = orange_db.set("redirect.enable", enable)
            result = success
        else
            result = false
        end

        if result then
            res:json({
                success = true,
                msg = (enable == true and "开启redirect成功" or "关闭redirect成功")
            })
        else
            res:json({
                success = false,
                msg = (enable == true and "开启redirect失败" or "关闭redirect失败")
            })
        end
    end
end)

API:get("/redirect/fetch_config", function(store)
    return function(req, res, next)
        local success, data = false, {}
        -- 查找enable
        local enable, err1 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "redirect.enable" }
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
            sql = "select `value` from redirect order by id asc"
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
end)

-- update the local cache to data stored in db
API:post("/redirect/sync", function(store)
    return function(req, res, next)
        local success, data = false, {}
        
        -- 查找enable
        local enable, err1 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "redirect.enable" }
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
            sql = "select `value` from redirect order by id asc"
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


        local ss, err3, forcible = orange_db.set("redirect.enable", data.enable)
        if not ss or err3 then
            return res:json({
                success = false,
                msg = "update local enable error"
            })
        end
        ss, err3, forcible = orange_db.set_json("redirect.rules", data.rules)
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
end)


-- create
API:post("/redirect/selectors/:id/rules", function(store)
    return function(req, res, next)
        local rule = req.body.rule
        rule = cjson.decode(rule)
        rule.id = utils.new_id()
        rule.time = utils.now()

        local success = false
        -- 插入到mysql
        local insert_result = store:insert({
            sql = "insert into redirect(`key`, `value`, `op_time`) values(?,?,?)",
            params = { rule.id, cjson.encode(rule), rule.time }
        })

        -- 插入成功，则更新本地缓存
        if insert_result then
            local redirect_rules = orange_db.get_json("redirect.rules") or {}
            table_insert(redirect_rules, rule)
            local s, err, forcible = orange_db.set_json("redirect.rules", redirect_rules)
            if s then
                success = true
            else
                ngx.log(ngx.ERR, "save redirect rules locally error: ", err)
            end
        else
            success = false
        end

        res:json({
            success = success,
            msg = success and "ok" or "failed"
        })
    end
end)

-- get
API:get("/redirect/selectors/:id/rules", function(store)
    return function(req, res, next)
        local data = {}
        data.enable = orange_db.get("redirect.enable")
        data.rules = orange_db.get_json("redirect.rules")

        res:json({
            success = true, 
            data = data
        })
    end
end)

 -- modify
API:put("/redirect/selectors/:id/rules", function(store)
    return function(req, res, next)
        local rule = req.body.rule
        rule = cjson.decode(rule)
        rule.time = utils.now()
    
        local update_result = store:delete({
            sql = "update redirect set `value`=?,`op_time`=? where `key`=?",
            params = { cjson.encode(rule), rule.time, rule.id }
        })

        if update_result then
            local old_rules = orange_db.get_json("redirect.rules") or {}
            local new_rules = {}
            for i, v in ipairs(old_rules) do
                if v.id == rule.id then
                    rule.time = utils.now()
                    table_insert(new_rules, rule)
                else
                    table_insert(new_rules, v)
                end
            end

            local success, err, forcible = orange_db.set_json("redirect.rules", new_rules)
            if err or forcible then
                ngx.log(ngx.ERR, "update local rules error when modifing:", err, ":", forcible)
                return res:json({
                    success = false,
                    msg = "update local rules error when modifing"
                })
            end

            res:json({
                success = success,
                msg = success and "ok" or "failed"
            })
        else
            res:json({
                success = false,
                msg = "update rule to db error"
            })
        end
    end
end)

 -- delete
API:delete("/redirect/selectors/:id/rules", function(store)
    return function(req, res, next)
        local rule_id = tostring(req.body.rule_id)
        if not rule_id or rule_id == "" then
            return res:json({
                success = false,
                msg = "error param: rule id shoule not be null."
            })
        end


        local delete_result = store:delete({
            sql = "delete from redirect where `key`=?",
            params = { rule_id }
        })

        if delete_result then
            local old_rules = orange_db.get_json("redirect.rules") or {}
            local new_rules = {}
            for i, v in ipairs(old_rules) do
                if v.id ~= rule_id then
                    table_insert(new_rules, v)
                end
            end
            local success, err, forcible = orange_db.set_json("redirect.rules", new_rules)
            if err or forcible then
                ngx.log(ngx.ERR, "update local rules error when deleting:", err, ":", forcible)
                return res:json({
                    success = false,
                    msg = "update local rules error when deleting"
                })
            end

            res:json({
                success = success,
                msg = success and "ok" or "failed"
            })
        else
            res:json({
                success = false,
                msg = "delete rule from db error"
            })
        end
    end
end)



-- get selectors
API:get("/redirect/selectors", function(store)
    return function(req, res, next)
        res:json({
            success = true, 
            data = {
                meta = orange_db.get_json("redirect.meta"),
                selectors = orange_db.get_json("redirect.selectors")
            }
        })
    end
end)

-- delete selector
--- 1) delete selector
--- 2) delete rules of it
--- 3) update meta
--- 4) update local meta & selectors
API:delete("/redirect/selectors", function(store)
    return function(req, res, next)

        local selector_id = tostring(req.body.selector_id)
        if not selector_id or selector_id == "" then
            return res:json({
                success = false,
                msg = "error param: selector id shoule not be null."
            })
        end

        -- get selector
        local selector = get_selector(store, selector_id)
        if not selector or not selector.value then
            return res:json({
                success = false,
                msg = "error: can not find selector#" .. selector_id
            })
        end

        -- delete rules of it
        local to_del_selector = utils.json_decode(selector.value)
        if not to_del_selector then
            return res:json({
                success = false,
                msg = "error: decode selector#" .. selector_id .. " failed"
            })
        end

        local to_del_rules_ids = table_concat(to_del_selector.rules or {}, ",")
        delete_rules_of_selector(store, to_del_rules_ids)

        -- update meta
        local meta = get_meta(store)
        local current_meta = utils.json_decode(meta.value)
        if not meta or not current_meta then
           return res:json({
                success = false,
                msg = "error: can not find meta"
            })
        end

        local current_selectors_ids = current_meta.selectors or {}
        local new_selectors_ids = {}
        for _, v in ipairs(current_selectors_ids) do
            if  selector_id ~= v then
                table_insert(new_selectors_ids, v)
            end
        end
        current_meta.selectors = new_selectors_ids

        local update_meta_result = update_meta(store, current_meta)
        if not update_meta_result then
            return res:json({
                success = false,
                msg = "error: update meta error"
            })
        end

        -- delete the very selector
        local delete_selector_result = delete_selector(store, selector_id)
        if not delete_selector_result then
            return res:json({
                success = false,
                msg = "error: delete the very selector error"
            })
        end

        -- update shared dict data
        --- update meta
        local success, err, forcible = orange_db.set_json("redirect.meta", current_meta)
        if err or not success then
            ngx.log(ngx.ERR, "update local redirect.meta error when deleting selector:", err, ":", forcible)
            return res:json({
                success = false,
                msg = "update local meta error when deleting"
            })
        end
        
        -- update selectors
        local current_selectors = orange_db.get_json("redirect.selectors")
        local new_selectors = {}
        for s_id, s in pairs(current_selectors) do
            if s_id ~= selector_id then
                new_selectors[s_id] = s
            end
        end
        success, err, forcible = orange_db.set_json("redirect.selectors", new_selectors)
        if err or not success then
            ngx.log(ngx.ERR, "update local redirect.selectors error when deleting selector:", err, ":", forcible)
            return res:json({
                success = false,
                msg = "update local selectors error when deleting selector"
            })
        end

        res:json({
            success = true,
            msg = "succeed to delete selector"
        })
    end
end)

-- create a selector
API:post("/redirect/selectors", function(store)
    return function(req, res)
        local selector = req.body.selector
        selector = cjson.decode(selector)
        selector.id = utils.new_id()
        selector.time = utils.now()

        local success = false
        -- 插入到mysql
        local insert_result = store:insert({
            sql = "insert into redirect(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
            params = { selector.id, cjson.encode(selector), "selector", selector.time }
        })

        -- 插入成功，则更新本地缓存
        if insert_result then
            local selectors = orange_db.get_json("redirect.selectors") or {}
            table_insert(selectors, selector)
            local s, err, forcible = orange_db.set_json("redirect.selectors", selectors)
            if s then
                success = true
            else
                ngx.log(ngx.ERR, "update redirect selectors locally after creating error: ", err)
            end
        else
            success = false
        end

        res:json({
            success = success,
            msg = success and "ok" or "failed"
        })
    end
end)

-- update
API:put("/redirect/selectors", function(store)
    return function(req, res, next)
        -- 更新selector
    end
end)

-- update selectors order
API:put("/redirect/selectors/:id/order", function(store)
    return function(req, res, next)
        -- 更新meta
    end
end)

-- update selectors order
API:put("/redirect/selectors/:id/rules_order", function(store)
    return function(req, res, next)
        -- 更新meta
    end
end)


return API
