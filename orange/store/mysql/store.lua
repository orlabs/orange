local type = type
local mysql_db = require("orange.store.mysql.mysql_db")
local Store = require("orange.store.base")
local json = require("orange.utils.json")
local table_insert = table.insert
local table_concat = table.concat

local MySQLStore = Store:extend()

function MySQLStore:new(options)
    local name = options.name or "mysql-store"
    self.super.new(self, name)
    self.store_type = "mysql"
    local connect_config = options.connect_config
    self.mysql_addr = connect_config.host .. ":" .. connect_config.port
    self.data = {}
    self.db = mysql_db(options)
end

function MySQLStore:query(opts)
    if not opts or opts == "" then return nil end
    local param_type = type(opts)
    local res, err, sql, params
    if param_type == "string" then
        sql = opts
    elseif param_type == "table" then
        sql = opts.sql
        params = opts.params
    end

    res, err = self.db:query(sql, params)
    if err then
        ngx.log(ngx.ERR, "MySQLStore:query, error:", err, " sql:", sql)
        return nil
    end

    if res and type(res) == "table" and #res <= 0 then
        ngx.log(ngx.WARN, "MySQLStore:query empty, sql:", sql)
    end

    return res
end

function MySQLStore:insert(opts)
    if not opts or opts == "" then return false end

    local param_type = type(opts)
    local res, err
    if param_type == "string" then
        res, err = self.db:query(opts)
    elseif param_type == "table" then
        res, err = self.db:query(opts.sql, opts.params or {})
    end

    if res and not err then
        return true
    else
        ngx.log(ngx.ERR, "MySQLStore:insert error:", err)
        return false
    end
end

function MySQLStore:delete(opts)
    if not opts or opts == "" then return false end
    local param_type = type(opts)
    local res, err
    if param_type == "string" then
        res, err = self.db:query(opts)
    elseif param_type == "table" then
        res, err = self.db:query(opts.sql, opts.params or {})
    end

    if res and not err then
        return true
    else
        ngx.log(ngx.ERR, "MySQLStore:delete error:", err)
        return false
    end
end

function MySQLStore:update(opts)
    if not opts or opts == "" then return false end
    local param_type = type(opts)
    local res, err
    if param_type == "string" then
        res, err = self.db:query(opts)
    elseif param_type == "table" then
        res, err = self.db:query(opts.sql, opts.params or {})
    end

    if res and not err then
        return true
    else
        ngx.log(ngx.ERR, "MySQLStore:update error:", err)
        return false
    end
end

function MySQLStore:user_new(username, password, enable)
    return self.db:query("insert into dashboard_user(username, password, enable) values(?,?,?)",
        {username, password, enable})
end

function MySQLStore:user_query(username, password)
    local res, err = self.db:query("select * from dashboard_user where username=? and password=?", {username, password})
    return res, err
end

function MySQLStore:user_query_all()
    local result, err = self.db:query("select id, username, is_admin, create_time, enable from dashboard_user order by id asc")
    if not result or err or type(result) ~= "table" or #result < 1 then
        return nil, err
    else
        return result, err
    end
end

function MySQLStore:user_query_by_username(username)
    local res, err = self.db:query("select * from dashboard_user where username=? limit 1", {username})
    if not res or err or type(res) ~= "table" or #res ~=1 then
        return nil, err or "error"
    end
    return res[1], err
end

function MySQLStore:user_update_enable(username, enable)
    local res, err = self.db:query("update dashboard_user set enable=? where id=?", {tonumber(enable), tonumber(userid)})
    if not res or err then
        return false
    else
        return true
    end
    res, err = self.db:query("select * from dashboard_user where username=? limit 1", {username})
    if not res or err or type(res) ~= "table" or #res ~=1 then
        return nil, err or "error"
    end
    return res[1], err
end

function MySQLStore:user_update_pwd_and_enable(username, pwd, enable)
    local res, err = self.db:query("update dashboard_user set password=?, enable=? where username=?", {pwd, tonumber(enable), username})
    if not res or err then
        return false
    else
        return true
    end
end

function MySQLStore:user_delete(username)
    local res, err = self.db:query("delete from dashboard_user where id=?", { username })
    if not res or err then
        return false
    else
        return true
    end
end

function MySQLStore:node_new(name, ip, port, api_username, api_password)
    return self.db:query("insert into cluster_node (name,ip,port,api_username,api_password) values(?,?,?,?,?)",
        { name, ip, port, api_username, api_password })
end

function MySQLStore:node_query_all()
    local result, err = self.db:query("select * from cluster_node order by ip asc")

    if not result or err or type(result) ~= "table" or #result < 1 then
        return nil, err
    else
        return result, err
    end
end

function MySQLStore:node_update_node(id, name, ip, port, api_username, api_password)
    local res, err = self.db:query("update cluster_node set name=?,ip=?,port=?,api_username=?,api_password=? where id=?", { name, ip, port, api_username, api_password, tonumber(id) })
    if not res or err then
        return false
    else
        return true
    end
end

function MySQLStore:node_delete(id)
    local res, err = self.db:query("delete from cluster_node where id=?", { tonumber(id) })
    if not res or err then
        return false
    else
        return true
    end
end

function MySQLStore:node_query_by_ip(ip, port)
    local result, err = self.db:query("select * from cluster_node where ip=?", { ip })
    if not result or err or type(result) ~= "table" or #result ~= 1 then
        return nil, err
    else
        return result[1], err
    end
end

function MySQLStore:get_selectors(plugin)
    local options = {
        sql = "select * from " .. plugin .. " where `type` = ?",
        params = {"selector"}
    }
    local res = MySQLStore.query(self, options)
    if res and type(res) == "table" then
        for _, s in ipairs(res) do
            s.value = json.decode(s.value or "{}")
        end
    end
    return res
end

function MySQLStore:delete_selector(plugin, selector_id)
    local options = {
        sql = "delete from " .. plugin .. " where `key` = ? and `type` = ?",
        params = { selector_id, "selector" }
    }
    local delete_result, err = MySQLStore.delete(self, options)
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete selector err, ", selector_id)
        return false
    end
end

function MySQLStore:create_selector(plugin, selector)
    local options = {
        sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
        params = { selector.id, json.encode(selector), "selector", selector.time }
    }
    return MySQLStore.insert(self, options)
end

function MySQLStore:get_selector(plugin, selector_id)
    local options = {
        sql = "select * from " .. plugin .. " where `key` = ? and `type` = ? limit 1",
        params = { selector_id, "selector" }
    }
    local selector, err = MySQLStore.query(self, options)
    if not err and selector and type(selector) == "table" and #selector > 0 then
        selector[1].value = json.decode(selector[1].value or "{}")
        return selector[1]
    end
    return nil, err
end

function MySQLStore:update_selector(plugin, selector)
    local selector_json_str = json.encode(selector)
    if not selector_json_str then
        ngx.log(ngx.ERR, "encode error: selector to save is not json format.")
        return false
    end
    local options = {
        sql = "update " .. plugin .. " set `value` = ? where `key`=? and `type` = ?",
        params = {selector_json_str, selector.id, "selector"}
    }
    local result = MySQLStore.update(self, options)
    return result
end

function MySQLStore:get_rules(plugin, rule_ids)
    local options = {
        sql = "select * from " .. plugin .. " where `type`=?",
        params = {"rule" }
    }
    if rule_ids and type(rule_ids) == "table" and #rule_ids > 0 then
        local to_concat = {}
        for _, r in ipairs(rule_ids) do
            table_insert(to_concat, "'" .. r .. "'")
        end
        local to_get_rules_ids = table_concat(to_concat, ",")
        if not to_get_rules_ids or to_get_rules_ids == "" then
            return {}
        end
        options = {
            sql = "select * from " .. plugin .. " where `key` in ( " .. to_get_rules_ids .. ") and `type`=?",
            params = {"rule" }
        }
    end
    local res, err = MySQLStore.query(self, options)
    if res then
        for _, r in ipairs(res) do
            r.value = json.decode(r.value or "{}")
        end
    end
    return res, err
end

function MySQLStore:delete_rule(plugin, rule_id)
    if not rule_id or rule_id == "" then
        return true
    end
    local options = {
        sql = "delete from " .. plugin .. " where `key` in ('" .. rule_id .. "') and `type`=?",
        params = { "rule" }
    }
    local delete_result, err = MySQLStore.delete(self, options)
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete rules of selector err, ", err)
        return false
    end
end

function MySQLStore:delete_rules_of_selector(plugin, rule_ids)
    local to_concat = {}
    for _, r in ipairs(rule_ids) do
        table_insert(to_concat, "'" .. r .. "'")
    end
    local to_delete_rules_ids = table_concat(to_concat, ",")
    if not to_delete_rules_ids or to_delete_rules_ids == "" then
        return true
    end
    local options = {
        sql = "delete from " .. plugin .. " where `key` in (" .. to_delete_rules_ids .. ") and `type`=?",
        params = { "rule" }
    }
    local delete_result = MySQLStore.delete(self, options)
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete rules of selector err, ", rule_ids)
        return false
    end
end

function MySQLStore:update_rule(plugin, rule)
    local options = {
        sql = "update " .. plugin .. " set `value`=?,`op_time`=? where `key`=? and `type`=?",
        params = { json.encode(rule), rule.time, rule.id, "rule" }
    }
    return MySQLStore.update(self, options, rule)
end

function MySQLStore:create_rule(plugin, rule)
    local options = {
        sql = "insert into " .. plugin .. "(`key`, `value`, `op_time`, `type`) values(?,?,?,?)",
        params = { rule.id, json.encode(rule), rule.time, "rule" }
    }
    return MySQLStore.insert(self, options)
end

function MySQLStore:get_meta(plugin)
    local options = {
        sql = "select * from " .. plugin .. " where `type` = ? limit 1",
        params = {"meta"}
    }
    local meta, err = MySQLStore.query(self, options)
    if not err and meta and type(meta) == "table" and #meta > 0 then
        if meta[1] then
            return json.decode(meta[1].value or "{}")
        end
        return nil
    else
        ngx.log(ngx.ERR, "[FATAL ERROR]meta not found while it must exist.")
        return nil
    end
end

function MySQLStore:update_meta(plugin, meta)
    local meta_json_str = json.encode(meta)
    if not meta_json_str then
        ngx.log(ngx.ERR, "encode error: meta to save is not json format.")
        return false
    end
    local options = {
        sql = "update " .. plugin .. " set `value` = ? where `type` = ?",
        params = {meta_json_str, "meta"}
    }
    return MySQLStore.update(self, options)
end

function MySQLStore:update_enable(plugin, enable)
    local plugin_enable = "0"
    if enable then plugin_enable = "1" end
    local options = {
        sql = "replace into meta SET `key`=?, `value`=?",
        params = { plugin .. ".enable", plugin_enable }
    }
    return MySQLStore.update(self,options)
end

function MySQLStore:get_enable(plugin)
    local options = {
        sql = "select `value` from meta where `key`=?",
        params = { plugin .. ".enable" }
    }
    local enable = MySQLStore.query(self, options)
    if enable and type(enable) == "table" and #enable > 0 then
        return enable[1].value == "1"
    end
    return false
end

return MySQLStore
