local ERR = ngx.ERR
local etcd = require("orange.lib.etcd")
local Store = require("orange.store.base")
local EtcdStore = Store:extend()
local table_insert = table.insert

function EtcdStore:new(options)
    local name = options.name or "etcd-store"
    self.super.new(self, name)
    self.store_type = "etcd"
    local config = options.connect_config
    local ops = {
        host = "http://" .. config.host .. ":" .. config.port,
        timeout = config.timeout
    }
    self.ops = ops
end

----------------- user manage start ---------------------------
function EtcdStore:user_new(username, password, enable)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    local val = {
        password = password,
        enable = enable
    }
    return  EtcdStore.insert(self, key, val)
end

function EtcdStore:user_query(username, password)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    return EtcdStore.query(self, key)
end

function EtcdStore:user_query_all()
    local key = context.config.store_etcd.default_path .. "user/"
    local result, err =  EtcdStore.query(self, key)
    if not result or err or type(result) ~= "table" then
        return nil, err
    else
        return result, err
    end
end

function EtcdStore:user_query_by_username(username)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    local result, err =  EtcdStore.query(self, key)
    if not result or err or type(result) ~= "table" then
        return nil, err
    else
        if result.body.node then
            return result.body.node.value
        end
        return nil, err
    end
end

function EtcdStore:user_update_enable(username, enable)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    local user_info, err = self:user_query_by_username(username)
    if err ~= nil then
        ngx.log(ngx.ERR, "Failed to get user, username=" .. username)
        return false
    end
    user_info.enable = enable
    local res, err = EtcdStore.update(self, key, user_info)
    if not res or err then
        return false
    else
        return true
    end
end

function EtcdStore:user_update_pwd_and_enable(username, pwd, enable)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    local val = {
        password = pwd,
        enable = enable
    }
    local res, err = EtcdStore.update(self, key, val)
    if not res or err then
        return false
    else
        return true
    end
end

function EtcdStore:user_delete(username)
    local key = context.config.store_etcd.default_path .. "user/" .. username
    local res, err = EtcdStore.delete(self, key)
    if not res or err then
        return false
    else
        return true
    end
end
----------------- user manage end ---------------------------

----------------- node manage start ---------------------------
function EtcdStore:node_new(name, ip, port, api_username, api_password)
    local val = {
        id = utils.new_id(),
        name = name,
        ip = ip,
        port = port,
        api_username = api_username,
        api_password = api_password
    }
    local key = context.config.store_etcd.default_path .. "node/nodes/" .. val.id
    return EtcdStore.insert(self, key, val)
end

function EtcdStore:node_query_all()
    local key = context.config.store_etcd.default_path .. "node/nodes"
    local result, err = EtcdStore.query(self, key)
    if not result or err or type(result) ~= "table" or result.status ~= 200 then
        return nil, err
    else
        if result.body.node.nodes then
            local nodes = result.body.node.nodes
            local res = {}
            for _, node in ipairs(nodes) do
                table_insert(res, node.value)
            end
            return res
        end
        return nil, err
    end
end

function EtcdStore:node_update_node(id, name, ip, port, api_username, api_password)
    local key = context.config.store_etcd.default_path .. "node/nodes/" .. id
    local val = {
        id = id,
        name = name,
        ip = ip,
        port = port,
        api_username = api_username,
        api_password = api_password
    }
    local res, err = EtcdStore.update( self, key, val)
    if not res or err then
        return false
    else
        return true
    end
end

function EtcdStore:node_delete(id)
    local key = context.config.store_etcd.default_path .. "node/nodes/" .. id
    local res, err = EtcdStore.delete(self, key)
    if not res or err then
        return false
    else
        return true
    end
end

function EtcdStore:node_query_by_ip(ip, port)
    local key = context.config.store_etcd.default_path .. "node/nodes/" .. ip .. "-" .. port
    local res, err = EtcdStore.query(self, key)
    if not res or err then
        return false
    else
        return true
    end
end
----------------- node manage end ---------------------------
function EtcdStore:get_selectors(plugin)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/selectors"
    local res, err = EtcdStore.query(self, key)
    if res and res.status == 200 then
        return res.body.node.nodes or {}
    end
    return nil, err
end

function EtcdStore:delete_selector(plugin, selector_id)
    local key = context.config.store_etcd.default_path .. plugin .. "/selectors/" .. selector_id
    local delete_result, err = EtcdStore.delete(self, key)
    if delete_result then
        return true
    else
        ngx.log(ngx.ERR, "delete selector err, ", selector_id)
        return false
    end
end

function EtcdStore:create_selector(plugin, selector)
    local key = context.config.store_etcd.default_path .. plugin .. "/selectors/" .. selector.id
    return EtcdStore.insert(self, key, selector)
end

function EtcdStore:get_selector(plugin, selector_id)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/selectors/" .. selector_id
    local res, err = EtcdStore.query(self, key)
    if res and res.status == 200 then
        return res.body.node or {}
    end
    return nil, err
end

function EtcdStore:update_selector(plugin, selector)
    local key = context.config.store_etcd.default_path .. plugin .. "/selectors/" .. selector.id
    local result = EtcdStore.update(self, key, selector)
    return result
end

function EtcdStore:get_rules(plugin)
    local key = context.config.store_etcd.default_path .. plugin .. "/rules"
    local rules_res, err = EtcdStore.query(self, key)
    if err then
        return false, err
    end
    local rules = rules_res.body.node.nodes or {}
    return rules, err
end

function EtcdStore:delete_rules_of_selector(plugin, rule_ids)
    local config = context.config
    local keys = {}
    for _, rule_id in ipairs(rule_ids) do
        local key = config.store_etcd.default_path .. plugin .. "/rules/" .. rule_id
        table_insert(keys, key)
    end
    return EtcdStore.delete_keys(self, keys)
end

function EtcdStore:delete_rule(plugin, rule_id)
    if not rule_id or rule_id == "" then
        return true
    end
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/rules/" .. rule_id
    return EtcdStore.delete(self, key)
end

function EtcdStore:update_rule(plugin, rule)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/rules/" .. rule.id
    return EtcdStore.update(self, key, rule)
end

function EtcdStore:create_rule(plugin, rule)
    local key = context.config.store_etcd.default_path .. plugin .. "/rules/" .. rule.id
    return EtcdStore.insert(self, key, rule)
end

function EtcdStore:get_meta(plugin)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/meta"
    local res, err = EtcdStore.query(self, key)
    if err then
        return nil, err
    end
    return res.body.node.value or {}
end

function EtcdStore:update_meta(plugin, meta)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/meta"
    return EtcdStore.update(self, key, meta)
end

function EtcdStore:update_enable(plugin, enable)
    local enable_values = {
        enable = enable
    }
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/enable"
    return EtcdStore.update(self, key, enable_values)
end

function EtcdStore:get_enable(plugin)
    local config = context.config
    local key = config.store_etcd.default_path .. plugin .. "/enable"
    local res, err = EtcdStore.query(self, key)
    if err then
        ngx.log(ngx.ERR, "Failed to query, key=" .. key)
        return nil, err
    end
    if res.body.node then
        return res.body.node.value.enable
    end
    return false
end

function EtcdStore:query(key)
    return etcd.get(self.ops, key)
end

function EtcdStore:insert(key, val, ttl)
    local res, err = etcd.set(self.ops, key, val, ttl)
    if err then
        ngx.log(ngx.ERR, "failed to do insert, err: " , err)
        return false
    end
    return true
end

function EtcdStore:delete(key)
    local res, err = etcd.delete(self.ops, key)
    if res and not err then
        return true
    else
        ngx.log(ngx.ERR, "EtcdStore:delete error:", err)
        return false
    end
end

function EtcdStore:delete_keys(keys)
    for _, key in ipairs(keys) do
        local res, err = etcd.delete(self.ops, key)
        if err then
            ngx.log(ngx.ERR, "EtcdStore:delete error:", err)
            return false
        end
    end
    return true
end

function EtcdStore:update(key, val, ttl)
    local res, err = etcd.set(self.ops, key, val, ttl)
    if res and res.status == 200 and not err then
        return true
    else
        ngx.log(ngx.ERR, "EtcdStore:update error:", err)
        return false
    end
end

return EtcdStore
