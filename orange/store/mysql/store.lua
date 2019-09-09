local type = type
local mysql_db = require("orange.store.mysql_db")
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

return MySQLStore
