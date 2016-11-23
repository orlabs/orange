local type = type
local mysql_db = require("orange.store.mysql_db")
local Store = require("orange.store.base")

local MySQLStore = Store:extend()

function MySQLStore:new(options)
    self._name = options.name or "mysql-store"
    MySQLStore.super.new(self, self._name)
    self.store_type = "mysql"
    local connect_config = options.connect_config
    self.mysql_addr = connect_config.host .. ":" .. connect_config.port
    self.data = {}
    self.db = mysql_db:new(options)
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

return MySQLStore
