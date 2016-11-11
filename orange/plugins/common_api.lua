local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local table_concat = table.concat
local cjson = require("cjson")
local orange_db = require("orange.store.orange_db")
local utils = require("orange.utils.utils")
local stringy = require("orange.utils.stringy")

local function delete_rules_of_selector(plugin, store, rule_ids)
    if not rule_ids or rule_ids == "" or type(rule_ids) ~= "table" then 
        return true
    end

    local to_concat = {}
    for _, r in ipairs(rule_ids) do
        table_insert(to_concat, "'" .. r .. "'")
    end
    local to_delete_rules_ids = table_concat(to_concat, ",")
    if not to_delete_rules_ids or to_delete_rules_ids == "" then
        return true
    end

    local delete_result = store:delete({
        sql = "delete from " .. plugin .. " where `key` in (" .. to_delete_rules_ids .. ") and `type`=?",
        params = { "rule" }
    })
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete rules of selector err, ", rule_ids)
        return false
    end
end

local function get_rules_of_selector(plugin, store, rule_ids)
    if not rule_ids or rule_ids == "" or type(rule_ids) ~= "table" then 
        return {}
    end

    local to_concat = {}
    for _, r in ipairs(rule_ids) do
        table_insert(to_concat, "'" .. r .. "'")
    end
    local to_get_rules_ids = table_concat(to_concat, ",")

    local rules, err = store:query({
        sql = "select * from " .. plugin .. " where `key` in ( " .. to_get_rules_ids .. ") and `type`=?",
        params = {"rule" }
    })
    if err then
        ngx.log(ngx.ERR, "error to get rules of selector, err:", err)
        return {}
    end

    if rules and type(rules) == "table" and #rules > 0 then
        local format_rules = {}

        -- reorder the rules as the order stored in selector
        for _, rule_id in ipairs(rule_ids) do
            for _, r in ipairs(rules) do
                local tmp = utils.json_decode(r.value)
                if tmp and tmp.id == rule_id then
                    table_insert(format_rules, tmp)
                end
            end
        end
        return format_rules
    else
        return {}
    end
end

local function delete_selector(plugin, store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then 
        return true
    end

    local delete_result = store:delete({
        sql = "delete from " .. plugin .. " where `key` = ? and `type` = ?",
        params = { selector_id, "selector" }
    })
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete selector err, ", selector_id)
        return false
    end
end

local function get_selector(plugin, store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then 
        return nil
    end

    local selector, err = store:query({
        sql = "select * from " .. plugin .. " where `key` = ? and `type` = ? limit 1",
        params = { selector_id, "selector" }
    })

    if not err and selector and type(selector) == "table" and #selector > 0 then
        return selector[1]
    end

    return nil
end

local function get_meta(plugin, store)
    local meta, err = store:query({
        sql = "select * from " .. plugin .. " where `type` = ? limit 1",
        params = {"meta"}
    })

    if not err and meta and type(meta) == "table" and #meta > 0 then
        return meta[1]
    else
        ngx.log(ngx.ERR, "[FATAL ERROR]meta not found while it must exist.")
        return nil
    end
end

local function update_meta(plugin, store, meta)
    if not meta or type(meta) ~= "table" then 
        return false
    end

    local meta_json_str = utils.json_encode(meta)
    if not meta_json_str then
        ngx.log(ngx.ERR, "encode error: meta to save is not json format.")
        return false
    end

    local result = store:update({
        sql = "update " .. plugin .. " set `value` = ? where `type` = ?",
        params = {meta_json_str, "meta"}
    })

    return result
end

local function update_selector(plugin, store, selector)
    if not selector or type(selector) ~= "table" then 
        return false
    end

    local selector_json_str = utils.json_encode(selector)
    if not selector_json_str then
        ngx.log(ngx.ERR, "encode error: selector to save is not json format.")
        return false
    end

    local result = store:update({
        sql = "update " .. plugin .. " set `value` = ? where `key`=? and `type` = ?",
        params = {selector_json_str, selector.id, "selector"}
    })

    return result
end

local function update_local_enable(plugin, store)
     -- 查找enable
    local enable, err = store:query({
        sql = "select `value` from meta where `key`=?",
        params = { plugin .. ".enable" }
    })

    if err then
        ngx.log(ngx.ERR, "error to find plugin's enable from storage when updating local enable, err:", err)
        return false
    end

    local real_enable = false
    if enable and type(enable) == "table" and #enable == 1 and enable[1].value == "1" then
        real_enable = true
    end

    local success, err, forcible = orange_db.set(plugin .. ".enable", real_enable)
    if err or not success then
        ngx.log(ngx.ERR, "update local plugin's enable error, err:", err)
        return false
    end

    return true
end

local function update_local_meta(plugin, store)
    local meta, err = store:query({
        sql = "select * from " .. plugin .. " where `type` = ? limit 1",
        params = {"meta"}
    })

    if err then
        ngx.log(ngx.ERR, "error to find meta from storage when updating local meta, err:", err)
        return false
    end

    if meta and type(meta) == "table" and #meta > 0 then
        local success, err, forcible = orange_db.set(plugin .. ".meta", meta[1].value or '{}')
        if err or not success then
            ngx.log(ngx.ERR, "update local plugin's meta error, err:", err)
            return false
        end
    else
        ngx.log(ngx.ERR, "can not find meta from storage when updating local meta")
    end

    return true
end

local function update_local_selectors(plugin, store)
    local selectors, err = store:query({
        sql = "select * from " .. plugin .. " where `type` = ?",
        params = {"selector"}
    })

    if err then
        ngx.log(ngx.ERR, "error to find selectors from storage when updating local selectors, err:", err)
        return false
    end

    local to_update_selectors = {}
    if selectors and type(selectors) == "table" then
        for _, s in ipairs(selectors) do
            to_update_selectors[s.key] = utils.json_decode(s.value or "{}")
        end

        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ngx.ERR, "update local plugin's selectors error, err:", err)
            return false
        end
    else
        ngx.log(ngx.ERR, "the size of selectors from storage is 0 when updating local selectors")
        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ngx.ERR, "update local plugin's selectors error, err:", err)
            return false
        end
    end

    return true
end

local function update_local_selector_rules(plugin, store, selector_id)
    if not selector_id then
        ngx.log(ngx.ERR, "error to find selector from storage when updating local selector rules, selector_id is nil")
        return false
    end

    local selector = get_selector(plugin, store, selector_id)
    if not selector or not selector.value then
        ngx.log(ngx.ERR, "error to find selector from storage when updating local selector rules, selector_id:", selector_id)
        return false
    end

    selector = utils.json_decode(selector.value)
    local rules_ids = selector.rules or {}
    local rules = get_rules_of_selector(plugin, store, rules_ids)

    local success, err, forcible = orange_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", rules)
    if err or not success then
        ngx.log(ngx.ERR, "update local rules of selector error, err:", err)
        return false
    end
    
    return true
end

local function create_selector(plugin, store, selector)
    return store:insert({
        sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
        params = { selector.id, cjson.encode(selector), "selector", selector.time }
    })
end

local function update_rule(plugin, store, rule)
    return store:update({
        sql = "update " .. plugin .. " set `value`=?,`op_time`=? where `key`=? and `type`=?",
        params = { cjson.encode(rule), rule.time, rule.id, "rule" }
    })
end

local function create_rule(plugin, store, rule)
    return store:insert({
        sql = "insert into " .. plugin .. "(`key`, `value`, `op_time`, `type`) values(?,?,?,?)",
        params = { rule.id, utils.json_encode(rule), rule.time, "rule" }
    })
end

local function get_enable(plugin, store)
    return store:query({
        sql = "select `value` from meta where `key`=?",
        params = { plugin .. ".enable" }
    })
end

local function update_enable(plugin, store, enable)
    return store:update({
        sql = "replace into meta SET `key`=?, `value`=?",
        params = { plugin .. ".enable", enable }
    })
end




-- build common apis
return function(plugin)
    local API = {}

    API["/" .. plugin .. "/enable"] = {
        POST = function(store)
            return function(req, res, next)
                local enable = req.body.enable
                if enable == "1" then enable = true else enable = false end

                local result = false
                
                local plugin_enable = "0"
                if enable then plugin_enable = "1" end
                local update_result = update_enable(plugin, store, plugin_enable)

                if update_result then
                    local success, err, forcible = orange_db.set(plugin .. ".enable", enable)
                    result = success
                else
                    result = false
                end

                if result then
                    res:json({
                        success = true,
                        msg = (enable == true and "开启插件成功" or "关闭插件成功")
                    })
                else
                    res:json({
                        success = false,
                        msg = (enable == true and "开启插件失败" or "关闭插件失败")
                    })
                end
            end
        end
    }

    API["/" .. plugin .. "/fetch_config"] = {
        GET = function(store)
            return function(req, res, next)
                local success, data = false, {}
                -- 查找enable
                local enable, err = get_enable(plugin, store)

                if err then
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

                -- 查找meta
                data.meta = get_meta(plugin, store) or {}

                res:json({
                    success = success,
                    data = data
                })
            end
        end
    }

    -- update the local cache to data stored in db
    API["/" .. plugin .. "/sync"] = {
        POST = function(store)
            return function(req, res, next)
                local update_enable_result = update_local_enable(plugin, store)
                local update_meta_result = update_local_meta(plugin, store)
                local update_selectors_result = update_local_selectors(plugin, store)
                if update_enable_result and update_meta_result and update_selectors_result then
                    return res:json({
                        success = true,
                        msg = "succeed to load config from store"
                    })
                else
                    ngx.log(ngx.ERR, "error to load config from store, update_enable:", update_enable_result, " update_meta:", update_meta_result, " update_selectors:", update_selectors_result)
                    return res:json({
                        success = false,
                        msg = "error to load config from store"
                    })
                end
            end
        end
    }


    API["/" .. plugin .. "/selectors/:id/rules"] = {
        POST = function(store) -- create
            return function(req, res, next)
                local selector_id = req.params.id
                local selector = get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    return res:json({
                        success = false,
                        msg = "selector not found when creating rule"
                    })
                end

                local current_selector = utils.json_decode(selector.value)
                if not current_selector then
                    return res:json({
                        success = false,
                        msg = "selector could not be decoded when creating rule"
                    })
                end

                local rule = req.body.rule
                rule = cjson.decode(rule)
                rule.id = utils.new_id()
                rule.time = utils.now()

                -- 插入到mysql
                local insert_result = create_rule(plugin, store, rule)

                -- 插入成功
                if insert_result then
                    -- update selector
                    current_selector.rules = current_selector.rules or {}
                    table_insert(current_selector.rules, rule.id)
                    local update_selector_result = update_selector(plugin, store, current_selector)
                    if not update_selector_result then
                        return res:json({
                            success = false,
                            msg = "update selector error when creating rule"
                        })
                    end

                    -- update local selectors
                    local update_local_selectors_result = update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to update local selectors when creating rule"
                        })
                    end

                    local update_local_selector_rules_result = update_local_selector_rules(plugin, store, selector_id)
                    if not update_local_selector_rules_result then
                        return res:json({
                            success = false,
                            msg = "error to update local rules of selector when creating rule"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "fail to create rule"
                    })
                end

                res:json({
                    success = true,
                    msg = "succeed to create rule"
                })
            end
        end, 

        GET = function(store)
            return function(req, res, next)
                local selector_id = req.params.id

                local rules = orange_db.get_json(plugin .. ".selector." .. selector_id .. ".rules") or {}
                res:json({
                    success = true, 
                    data = {
                        rules = rules
                    }
                })
            end
        end,

        PUT = function(store) -- modify
            return function(req, res, next)
                local selector_id = req.params.id
                local rule = req.body.rule
                rule = utils.json_decode(rule)
                rule.time = utils.now()
            
                local update_result = update_rule(plugin, store, rule)

                if update_result then
                    local old_rules = orange_db.get_json(plugin .. ".selector." .. selector_id .. ".rules") or {}
                    local new_rules = {}
                    for i, v in ipairs(old_rules) do
                        if v.id == rule.id then
                            rule.time = utils.now()
                            table_insert(new_rules, rule)
                        else
                            table_insert(new_rules, v)
                        end
                    end

                    local success, err, forcible = orange_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", new_rules)
                    if err or forcible then
                        ngx.log(ngx.ERR, "update local rules error when modifing:", err, ":", forcible)
                        return res:json({
                            success = false,
                            msg = "update local rules error when modifing"
                        })
                    end

                    return res:json({
                        success = success,
                        msg = success and "ok" or "failed"
                    })
                end

                res:json({
                    success = false,
                    msg = "update rule to db error"
                })
            end
        end,

        DELETE = function(store)
            return function(req, res, next)
                local selector_id = req.params.id
                local selector = get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    return res:json({
                        success = false,
                        msg = "selector not found when deleting rule"
                    })
                end

                local current_selector = utils.json_decode(selector.value)
                if not current_selector then
                    return res:json({
                        success = false,
                        msg = "selector could not be decoded when deleting rule"
                    })
                end

                local rule_id = tostring(req.body.rule_id)
                if not rule_id or rule_id == "" then
                    return res:json({
                        success = false,
                        msg = "error param: rule id shoule not be null."
                    })
                end

                local delete_result = store:delete({
                    sql = "delete from " .. plugin .. " where `key`=? and `type`=?",
                    params = { rule_id, "rule"}
                })

                if delete_result then
                    -- update selector
                    local old_rules_ids = current_selector.rules or {}
                    local new_rules_ids = {}
                    for _, orid in ipairs(old_rules_ids) do
                        if orid ~= rule_id then
                            table_insert(new_rules_ids, orid)
                        end
                    end
                    current_selector.rules = new_rules_ids

                    local update_selector_result = update_selector(plugin, store, current_selector)
                    if not update_selector_result then
                        return res:json({
                            success = false,
                            msg = "update selector error when deleting rule"
                        })
                    end

                    -- update local selectors
                    local update_local_selectors_result = update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to update local selectors when deleting rule"
                        })
                    end

                    -- update local rules of selector
                    local update_local_selector_rules_result = update_local_selector_rules(plugin, store, selector_id)
                    if not update_local_selector_rules_result then
                        return res:json({
                            success = false,
                            msg = "error to update local rules of selector when creating rule"
                        })
                    end
                else
                    res:json({
                        success = false,
                        msg = "delete rule from db error"
                    })
                end

                res:json({
                    success = true,
                    msg = "succeed to delete rule"
                })
            end
        end
    }

    -- update rules order
    API["/" .. plugin .. "/selectors/:id/rules/order"] = {
        PUT = function(store)
            return function(req, res, next)
                local selector_id = req.params.id

                local new_order = req.body.order
                if not new_order or new_order == "" then
                    return res:json({
                        success = false, 
                        msg = "error params"
                    })
                end

                local tmp = stringy.split(new_order, ",")
                local rules = {}
                if tmp and type(tmp) == "table" and #tmp > 0 then
                    for _, t in ipairs(tmp) do
                        table_insert(rules, t)
                    end
                end

                local update_selector_result, update_local_selectors_result, update_local_selector_rules_result
                local selector = get_selector(plugin, store, selector_id)
                if not selector or not selector.value then 
                    ngx.log(ngx.ERR, "error to find selector when resorting rules of it")
                    return res:json({
                        success = true, 
                        msg = "error to find selector when resorting rules of it"
                    })
                else
                    local new_selector = utils.json_decode(selector.value) or {}
                    new_selector.rules = rules
                    update_selector_result = update_selector(plugin, store, new_selector)
                    if update_selector_result then
                        update_local_selectors_result = update_local_selectors(plugin, store)
                    end
                end

                if update_selector_result and update_local_selectors_result then
                    update_local_selector_rules_result = update_local_selector_rules(plugin, store, selector_id)
                    if update_local_selector_rules_result then
                        return res:json({
                            success = true,
                            msg = "succeed to resort rules"
                        })
                    end
                end

                ngx.log(ngx.ERR, "error to update local data when resorting rules, update_selector_result:", update_selector_result, " update_local_selectors_result:", update_local_selectors_result, " update_local_selector_rules_result:", update_local_selector_rules_result)
                res:json({
                    success = false,
                    msg = "fail to resort rules"
                })
            end
        end
    }


    API["/" .. plugin .. "/selectors"] = {
        GET = function(store) -- get selectors
            return function(req, res, next)
                res:json({
                    success = true, 
                    data = {
                        enable = orange_db.get(plugin .. ".enable"),
                        meta = orange_db.get_json(plugin .. ".meta"),
                        selectors = orange_db.get_json(plugin .. ".selectors")
                    }
                })
            end
        end,

        DELETE = function(store) -- delete selector
            --- 1) delete selector
            --- 2) delete rules of it
            --- 3) update meta
            --- 4) update local meta & selectors
            return function(req, res, next)

                local selector_id = tostring(req.body.selector_id)
                if not selector_id or selector_id == "" then
                    return res:json({
                        success = false,
                        msg = "error param: selector id shoule not be null."
                    })
                end

                -- get selector
                local selector = get_selector(plugin, store, selector_id)
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

                local to_del_rules_ids = to_del_selector.rules or {}
                local d_result = delete_rules_of_selector(plugin, store, to_del_rules_ids)
                ngx.log(ngx.ERR, "delete rules of selector:", d_result)

                -- update meta
                local meta = get_meta(plugin, store)
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

                local update_meta_result = update_meta(plugin, store, current_meta)
                if not update_meta_result then
                    return res:json({
                        success = false,
                        msg = "error: update meta error"
                    })
                end

                -- delete the very selector
                local delete_selector_result = delete_selector(plugin, store, selector_id)
                if not delete_selector_result then
                    return res:json({
                        success = false,
                        msg = "error: delete the very selector error"
                    })
                end

                -- update local meta & selectors
                local update_local_meta_result = update_local_meta(plugin, store)
                local update_local_selectors_result = update_local_selectors(plugin, store)
                if update_local_meta_result and update_local_selectors_result then
                    return res:json({
                        success = true,
                        msg = "succeed to delete selector"
                    })
                else
                    ngx.log(ngx.ERR, "error to delete selector, update_meta:", update_local_meta_result, " update_selectors:", update_local_selectors_result)
                    return res:json({
                        success = false,
                        msg = "error to udpate local data when deleting selector"
                    })
                end
            end
        end,

        POST = function(store) -- create a selector
            return function(req, res)
                local selector = req.body.selector
                selector = cjson.decode(selector)
                selector.id = utils.new_id()
                selector.time = utils.now()

                -- create selector
                local insert_result = create_selector(plugin, store, selector)

                -- update meta
                local meta = get_meta(plugin, store)
                local current_meta = utils.json_decode(meta and meta.value or "{}")
                if not meta or not current_meta then
                   return res:json({
                        success = false,
                        msg = "error: can not find meta when creating selector"
                    })
                end
                current_meta.selectors = current_meta.selectors or {}
                table_insert(current_meta.selectors, selector.id)
                local update_meta_result = update_meta(plugin, store, current_meta)
                if not update_meta_result then
                    return res:json({
                        success = false,
                        msg = "error: update meta error when creating selector"
                    })
                end

                -- update local meta & selectors
                if insert_result then
                    local update_local_meta_result = update_local_meta(plugin, store)
                    local update_local_selectors_result = update_local_selectors(plugin, store)
                    if update_local_meta_result and update_local_selectors_result then
                        return res:json({
                            success = true,
                            msg = "succeed to create selector"
                        })
                    else
                        ngx.log(ngx.ERR, "error to create selector, update_meta:", update_local_meta_result, " update_selectors:", update_local_selectors_result)
                        return res:json({
                            success = false,
                            msg = "error to udpate local data when creating selector"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "error to save data when creating selector"
                    })
                end
            end
        end,

        PUT = function(store) -- update
            return function(req, res, next)
                local selector = req.body.selector
                selector = cjson.decode(selector)
                selector.time = utils.now()
                -- 更新selector
                local update_selector_result = update_selector(plugin, store, selector)
                if update_selector_result then
                    local update_local_selectors_result = update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to local selectors when updating selector"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "error to update selector"
                    })
                end

                return res:json({
                    success = true,
                    msg = "succeed to update selector"
                })
            end
        end
    }



    -- update selectors order
    API["/" .. plugin .. "/selectors/order"] = {
        PUT = function(store)
            return function(req, res, next)
                local new_order = req.body.order
                if not new_order or new_order == "" then
                    return res:json({
                        success = false, 
                        msg = "error params"
                    })
                end

                local tmp = stringy.split(new_order, ",")
                local selectors = {}
                if tmp and type(tmp) == "table" and #tmp > 0 then
                    for _, t in ipairs(tmp) do
                        table_insert(selectors, t)
                    end
                end

                local update_meta_result, update_local_meta_result
                local meta = get_meta(plugin, store)
                if not meta or not meta.value then 
                    ngx.log(ngx.ERR, "error to find meta when resorting selectors")
                    return res:json({
                        success = true, 
                        msg = "error to find meta when resorting selectors"
                    })
                else
                    local new_meta = utils.json_decode(meta.value) or {}
                    new_meta.selectors = selectors
                    update_meta_result = update_meta(plugin, store, new_meta)
                    if update_meta_result then
                        update_local_meta_result = update_local_meta(plugin, store)
                    end
                end

                if update_meta_result and update_local_meta_result then
                    res:json({
                        success = true,
                        msg = "succeed to resort selectors"
                    })
                else
                    ngx.log(ngx.ERR, "error to update local meta when resorting selectors, update_meta_result:", update_meta_result, " update_local_meta_result:", update_local_meta_result)
                    res:json({
                        success = false,
                        msg = "fail to resort selectors"
                    })
                end
            end
        end
    }

    return API
end
