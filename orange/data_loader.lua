local ipairs = ipairs
local table_insert = table.insert
local table_concat = table.concat
local type = type
local xpcall = xpcall
local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")


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

local function get_rules_of_selector(plugin, store, rule_ids)
    if not rule_ids or type(rule_ids) ~= "table" or #rule_ids == 0 then 
        return {}
    end

    local to_concat = {}
    for _, r in ipairs(rule_ids) do
        table_insert(to_concat, "'" .. r .. "'")
    end
    local to_get_rules_ids = table_concat(to_concat, ",")
    if not to_get_rules_ids or to_get_rules_ids == "" then
        return {}
    end

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

local function init_rules_of_selector(plugin, store, selector_id)
    if not selector_id then
        ngx.log(ngx.ERR, "error: selector_id is nil")
        return false
    end

    local selector = get_selector(plugin, store, selector_id)
    if not selector or not selector.value then
        ngx.log(ngx.ERR, "error to find selector from storage when initializing plugin[" .. plugin .. "] local selector rules, selector_id:", selector_id)
        return false
    end

    selector = utils.json_decode(selector.value)
    local rules_ids = selector.rules or {}
    local rules = get_rules_of_selector(plugin, store, rules_ids)

    local success, err, forcible = orange_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", rules)
    if err or not success then
        ngx.log(ngx.ERR, "init plugin[" .. plugin .. "] local rules of selector error, err:", err)
        return false
    end
    
    return true
end

local function init_enable_of_plugin(plugin, store)
    -- 查找enable
    local enables, err = store:query({
        sql = "select `key`, `value` from meta where `key`=?",
        params = {plugin .. ".enable"}
    })

    if err then
        ngx.log(ngx.ERR, "Load `enable` of plugin[" .. plugin .. "], error: ", err)
        return false
    end

    if enables and type(enables) == "table" and #enables > 0 then
        orange_db.set(plugin .. ".enable", enables[1].value == "1")
    else
        orange_db.set(plugin .. ".enable", false)
    end

    return true
end

local function init_meta_of_plugin(plugin, store)
    local meta, err = store:query({
        sql = "select * from " .. plugin .. " where `type` = ? limit 1",
        params = {"meta"}
    })

    if err then
        ngx.log(ngx.ERR, "error to find meta from storage when initializing plugin[" .. plugin .. "] local meta, err:", err)
        return false
    end

    if meta and type(meta) == "table" and #meta > 0 then
        local success, err, forcible = orange_db.set(plugin .. ".meta", meta[1].value or '{}')
        if err or not success then
            ngx.log(ngx.ERR, "init local plugin[" .. plugin .. "] meta error, err:", err)
            return false
        end
    else
        ngx.log(ngx.ERR, "can not find meta from storage when initializing plugin[" .. plugin .. "] local meta")
    end

    return true
end

local function init_selectors_of_plugin(plugin, store)
    local selectors, err = store:query({
        sql = "select * from " .. plugin .. " where `type` = ?",
        params = {"selector"}
    })

    if err then
        ngx.log(ngx.ERR, "error to find selectors from storage when initializing plugin[" .. plugin .. "], err:", err)
        return false
    end

    local to_update_selectors = {}
    if selectors and type(selectors) == "table" then
        for _, s in ipairs(selectors) do
            to_update_selectors[s.key] = utils.json_decode(s.value or "{}")

            -- init this selector's rules local cache
            local init_rules_of_it = init_rules_of_selector(plugin, store, s.key)
            if not init_rules_of_it then
                return false
            end
        end

        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ngx.ERR, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    else
        ngx.log(ngx.ERR, "the size of selectors from storage is 0 when initializing plugin[" .. plugin .. "] local selectors")
        local success, err, forcible = orange_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ngx.ERR, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    end

    return true
end

--- load plugin's config from mysql
local function load_data_by_mysql(store, plugin)
    local ok, e
    ok = xpcall(function() 
        local v = plugin
        if not v or v == "" then
            ngx.log(ngx.ERR, "params error, the `plugin` is nil")
            os.exit(1)
        end

        if v == "stat" then
            return
        elseif v == "kvstore" then
            local init_enable = init_enable_of_plugin(v, store)
            if not init_enable then
                ngx.log(ngx.ERR, "load data of plugin[" .. v .. "] error, init_enable:", init_enable)
                os.exit(1)
            else
                ngx.log(ngx.ERR, "load data of plugin[" .. v .. "] success")
            end
        else -- ignore `stat` and `kvstore`
            local init_enable = init_enable_of_plugin(v, store)
            local init_meta = init_meta_of_plugin(v, store)
            local init_selectors_and_rules = init_selectors_of_plugin(v, store)
            if not init_enable or not init_meta or not init_selectors_and_rules then
                ngx.log(ngx.ERR, "load data of plugin[" .. v .. "] error, init_enable:", init_enable, " init_meta:", init_meta, " init_selectors_and_rules:", init_selectors_and_rules)
                return false
            else
                ngx.log(ngx.ERR, "load data of plugin[" .. v .. "] success")
            end
        end
    end, function()
        e = debug.traceback()
    end)

    if not ok or e then
        ngx.log(ngx.ERR, "[load plugin's data error], plugin:", plugin, " error:", e)
        return false
    end

    return true
end

return {
    load_data_by_mysql = load_data_by_mysql
}
