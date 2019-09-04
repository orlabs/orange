local ipairs = ipairs
local table_insert = table.insert
local table_concat = table.concat
local type = type
local xpcall = xpcall
local json = require("orange.utils.json")
local orange_db = require("orange.store.orange_db")
local ERR = ngx.ERR
local utils = require("orange.utils.utils")
local decode_json, encode_json
do
    local cjson = require "cjson.safe"
    decode_json = cjson.decode
    encode_json = cjson.encode
end

local _M = {
    desc = "store access & local cache manage"
}

function _M.get_selector(plugin, store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then
        return nil
    end
    local res, err = store:get_selector(plugin, selector_id)
    if err then
        ngx.log(ERR, "error to find meta from storage when initializing plugin[" .. plugin .. "] local meta, err:", err)
        return false
    end
    return res
end

function _M.get_rules_of_selector(plugin, store, selector, all_rules)
    if not (selector and selector.id) then
        ngx.log(ERR, "error: selector or selector_id is nil")
        return {}
    end

    local rule_ids = selector.rules
    if not rule_ids or type(rule_ids) ~= "table" or #rule_ids == 0 then
        return {}
    end

    if all_rules and type(all_rules) == "table" and #all_rules > 0 then
        local format_rules = {}

        -- reorder the rules as the order stored in selector
        for _, rule_id in ipairs(rule_ids) do
            for _, r in ipairs(all_rules) do
                local tmp = r.value
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

function _M.delete_rules_of_selector(plugin, store, rule_ids)
    if not rule_ids or rule_ids == "" or type(rule_ids) ~= "table" then
        return true
    end
    local res = store:delete_rules_of_selector(plugin, rule_ids)
    if res then
        return true
    else
        ngx.log(ERR, "delete rules of selector err, ", rule_ids)
        return false
    end
end

function _M.delete_selector(plugin, store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then
        return true
    end
    local delete_result, err = store:delete_selector(plugin, selector_id)
    if delete_result then
        return true
    else
        ngx.log(ERR, "delete selector err, ", selector_id)
        return false
    end
end

function _M.get_meta(plugin, store)
    local meta, err = store:get_meta(plugin)
    if not err and meta and type(meta) == "table" then
        return meta
    else
        ngx.log(ERR, "[FATAL ERROR]meta not found while it must exist.")
        return nil
    end
end

function _M.update_meta(plugin, store, meta)
    if not meta or type(meta) ~= "table" then
        return false
    end
    local meta_json_str = json.encode(meta)
    if not meta_json_str then
        ngx.log(ERR, "encode error: meta to save is not json format.")
        return false
    end
    local res, err = store:update_meta(plugin, meta)
    if err then
        ngx.log(ERR, "failed to update meta, err:", err)
        return false
    end
    return res
end

function _M.update_selector(plugin, store, selector)
    if not selector or type(selector) ~= "table" then
        return false
    end
    local result = store:update_selector(plugin, selector)
    return result
end

function _M.update_local_meta(plugin, store)
    local meta = _M.get_meta(plugin, store)
    if meta and type(meta) == "table" then
        local success, err, forcible = orange_db.set(plugin .. ".meta", encode_json(meta or {}))
        if err or not success then
            ngx.log(ERR, "update local plugin's meta error, err:", err)
            return false
        end
    else
        ngx.log(ERR, "can not find meta from storage when updating local meta")
    end
    return true
end

function _M.update_local_selectors(plugin, store)
    local selectors = store:get_selectors(plugin)
    local to_update_selectors = {}
    if selectors then
        for _, _node in ipairs(selectors) do
            local selector_id = _node.value.id
            to_update_selectors[selector_id] = _node.value or {}
        end

        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ERR, "update local plugin's selectors error, err:", err)
            return false
        end
    else
        ngx.log(ERR, "the size of selectors from storage is 0 when updating local selectors")
        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ERR, "update local plugin's selectors error, err:", err)
            return false
        end
    end
    return true
end

function _M.update_local_selector_rules(plugin, store, selector_id)
    if not selector_id then
        ngx.log(ERR, "error to find selector from storage when updating local selector rules, selector_id is nil")
        return false
    end

    local selector = _M.get_selector(plugin, store, selector_id)
    if not selector or not selector.value then
        ngx.log(ERR, "error to find selector from storage when updating local selector rules, selector_id:", selector_id)
        return false
    end

    selector = selector.value
    -- read all rules
    local rules_res, err = store:get_rules(plugin)
    local rules = _M.get_rules_of_selector(plugin, store, selector, rules_res)
    local success, err, forcible = orange_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", rules)
    if err or not success then
        ngx.log(ERR, "update local rules of selector error, err:", err)
        return false
    end
    return true
end

function _M.create_selector(plugin, store, selector)
    return store:create_selector(plugin, selector)
end

function _M.update_rule(plugin, store, rule)
    local res, err = store:update_rule(plugin, rule)
    if err then
        ngx.log(ERR, "update rule failed, err:", err)
        return false
    end
    return res
end

function _M.create_rule(plugin, store, rule)
    local res, err = store:create_rule(plugin, rule)
    if not res and err then
        ngx.log(ERR, "failed to create rule, err:" .. err)
        return false
    end
    return true
end

function _M.update_enable(plugin, store, enable)
    return store:update_enable(plugin, enable)
end


-- ########################### local cache init start #############################
function _M.init_rules_of_selector(plugin, store, selector, all_rules)
    if not (selector and selector.id) then
        ngx.log(ERR, "error: selector or selector_id is nil")
        return false
    end

    local rules_ids = selector.rules or {}
    local rules = {}
    -- reorder the rules as the order stored in selector
    for _, rule_id in ipairs(rules_ids) do
        for _, r in ipairs(all_rules) do
            local tmp = r.value
            --local tmp = json.decode(r.value)
            if tmp and tmp.id == rule_id then
                table_insert(rules, tmp)
            end
        end
    end
    local success, err, forcible = orange_db.set_json(plugin .. ".selector." .. selector.id .. ".rules", rules)
    if err or not success then
        ngx.log(ERR, "init plugin[" .. plugin .. "] local rules of selector error, err:", err)
        return false
    end
    return true
end

function _M.init_enable_of_plugin(plugin, store, config)
    -- 查找enable
    local enable = store:get_enable(plugin)
    orange_db.set(plugin .. ".enable", enable)
    return true
end

function _M.init_meta_of_plugin(plugin, store, config)
    -- 查找enable
    local meta, err = store:get_meta(plugin)
    if err then
        ngx.log(ERR, "error to find meta from storage when initializing plugin[" .. plugin .. "] local meta, err:", err)
        return false
    end

    if meta and type(meta) == "table" then
        --ngx.log(ERR, "init_meta_of_plugin DATA ======================== " .. type(meta.body.node.value)) table
        local success, err, forcible = orange_db.set(plugin .. ".meta", encode_json(meta or {}))
        if err or not success then
            ngx.log(ERR, "init local plugin[" .. plugin .. "] meta error, err:", err)
            return false
        end
    else
        ngx.log(ERR, "can not find meta from storage when initializing plugin[" .. plugin .. "] local meta")
    end

    return true
end

function _M.init_selectors_of_plugin(plugin, store, config)
    -- 查找enable
    local selectors = store:get_selectors(plugin)

    local to_update_selectors = {}

    if selectors then
        -- read all rules
        local rules, err = store:get_rules(plugin)
        if err then
            ngx.log(ERR, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
        --local rules = rules_res.body.node.nodes
        for _, _node in ipairs(selectors) do
            local selector_id = _node.value.id
            to_update_selectors[selector_id] = _node.value or {}

            local init_rules_of_it = _M.init_rules_of_selector(plugin, store, _node.value, rules)
            if not init_rules_of_it then
                return false
            end
        end
        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ERR, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    else
        ngx.log(ERR, "the size of selectors from storage is 0 when initializing plugin[" .. plugin .. "] local selectors")
        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ERR, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    end

    return true
end
-- ########################### local cache init end #############################


-- ########################### for data(configurations in storage) preview #############################
function _M.compose_plugin_data(store, plugin)
    local data = {}
    local ok, e
    ok = xpcall(function()
        -- get enable
        local enable = store:get_enable(plugin)
        data[plugin .. ".enable"] = enable

        -- get meta
        local meta, err = store:get_meta(plugin)
        if err then
            ngx.log(ERR, "error to find meta from storage when fetching data of plugin[" .. plugin .. "], err:", err)
            return false
        end

        if meta and type(meta) == "table" then
            data[plugin .. ".meta"] = meta or {}
        else
            ngx.log(ERR, "can not find meta from storage when fetching data of plugin[" .. plugin .. "]")
            return false
        end

        -- get selectors and its rules
        local selectors, err = store:get_selectors(plugin)
        if err then
            ngx.log(ERR, "error to find selectors from storage when fetching data of plugin[" .. plugin .. "], err:", err)
            return false
        end
        if selectors then
            -- read all rules
            local rules, err = store:get_rules(plugin)
            local to_update_selectors = {}
            for _, _node in ipairs(selectors) do
                local selector_id = _node.value.id
                -- init this selector's rules local cache
                if not selector_id then
                    ngx.log(ERR, "error: selector_id is nil")
                    return false
                end
                to_update_selectors[selector_id] = _node.value or {}

                -- init this selector's rules local cache
                local rules = _M.get_rules_of_selector(plugin, store, _node.value, rules)
                data[plugin .. ".selector." .. selector_id .. ".rules"] = rules
            end
            data[plugin .. ".selectors"]= to_update_selectors
        else
            ngx.log(ERR, "the size of selectors from storage is 0 when fetching data of plugin[" .. plugin .. "] selectors")
            data[plugin .. ".selectors"] = {}
        end
        return true, data
    end, function()
        e = debug.traceback()
    end)

    if not ok or e then
        ngx.log(ERR, "[fetch plugin's data error], plugin:", plugin, " error:", e)
        return false
    end

    return true, data
end

-- ########################### init cache when starting gateway #############################
function _M.load_data(store, plugin, config)
    local ok, e
    ok = xpcall(function()
        local v = plugin
        if not v or v == "" then
            ngx.log(ERR, "params error, the `plugin` is nil")
            return false
        end

        if v == "stat" or v == "prometheus" then
            return
        elseif v == "kvstore" then
            local init_enable = _M.init_enable_of_plugin(v, store, config)
            if not init_enable then
                ngx.log(ERR, "load data of plugin[" .. v .. "] error, init_enable:", init_enable)
                return false
            else
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] success")
            end
        else -- ignore `stat` and `kvstore`
            local init_enable = _M.init_enable_of_plugin(v, store, config)
            local init_meta = _M.init_meta_of_plugin(v, store, config)
            local init_selectors_and_rules = _M.init_selectors_of_plugin(v, store, config)
            if not init_enable or not init_meta or not init_selectors_and_rules then
                ngx.log(ERR, "load data of plugin[" .. v .. "] error, init_enable:", init_enable, " init_meta:", init_meta, " init_selectors_and_rules:", init_selectors_and_rules)
                return false
            else
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] success")
            end
        end
    end, function()
        e = debug.traceback()
    end)

    if not ok or e then
        ngx.log(ERR, "[load plugin's data error], plugin:", plugin, " error:", e)
        return false
    end

    return true
end

-- only ETCD need to use
function _M.regist_node(store, config, delay)
    local d = utils.get_hostname()
    local ip = ip_utils.get_ipv4()
    local port = config.store_etcd.regist.port
    local username, password
    local credentials = config.api.credentials
    for _, credential in ipairs(credentials) do
        username = credential.username
        password = credential.password
    end
    local val = {
        id = utils.new_id(),
        name = d,
        ip = ip,
        port = port,
        api_username = username,
        api_password = password
    }
    local store_etcd = config.store_etcd
    local key_prefix = store_etcd.default_path .. "node/nodes/"
    local key = key_prefix .. ip .. ":" .. port
    local res, err = store.insert(store, key, val, delay * 3)
    if err ~= nil then
        ngx.log(ERR, "failed to register myself to etcd. err:" .. err)
    end
    return res, err
end

return _M
