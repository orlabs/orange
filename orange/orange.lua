require "bit32"
local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local pcall = pcall
local type = type
local require = require
local cjson = require("cjson")
local utils = require("orange.utils.utils")
local config_loader = require("orange.utils.config_loader")
local orange_db = require("orange.store.orange_db")
local base_plugin = require("orange.plugins.base")

local HEADERS = {
    PROXY_LATENCY = "X-Orange-Proxy-Latency",
    UPSTREAM_LATENCY = "X-Orange-Upstream-Latency",
}

local loaded_plugins = {}
local access_plugins = {}
local redirect_plugins = {}
local rewrite_plugins = {}
local header_filter_plugins = {}
local body_filter_plugins = {}

local function plugin_priority_compare(a, b)
    local priority_a = a.handler.PRIORITY or 0
    local priority_b = b.handler.PRIORITY or 0
    return priority_a > priority_b
end

local function load_node_plugins(config, store)
    ngx.log(ngx.DEBUG, "Discovering used plugins")

    local sorted_plugins = {}
    local plugins = config.plugins

    for _, v in ipairs(plugins) do
        local loaded, plugin_handler = utils.load_module_if_exists("orange.plugins." .. v .. ".handler")
        if not loaded then
            error("The following plugin is not installed: " .. v)
        else
            ngx.log(ngx.DEBUG, "Loading plugin: " .. v)
            table_insert(sorted_plugins, {
                name = v,
                handler = plugin_handler(store),
            })
        end
    end

    table_sort(sorted_plugins, plugin_priority_compare)

    return sorted_plugins
end

-- ms
local function now()
    return ngx.now() * 1000
end

---
-- modified usage: the origin is from `Kong`
-- @Deprecated
local function iter_plugins_for_req(loaded_plugins, is_access)
    if not ngx.ctx.plugin_conf_for_request then
        ngx.ctx.plugin_conf_for_request = {}
    end

    local i = 0
    local function get_next_plugin()
        i = i + 1
        return loaded_plugins[i]
    end

    local function get_next()
        local plugin = get_next_plugin()
        if plugin then
            if is_access then
                -- 根据是否是全局插件或者匹配的某个请求、用户插件加载不同配置
                ngx.ctx.plugin_conf_for_request[plugin.name] = {}
            end

            -- Return the configuration
            if ngx.ctx.plugin_conf_for_request[plugin.name] then
                return plugin, ngx.ctx.plugin_conf_for_request[plugin.name]
            end

            return get_next() -- Load next plugin
        end
    end

    return function()
        return get_next()
    end
end

local function load_data_by_file()
end

--- load data for orange and its plugins from MySQL
-- ${plugin}.enable
-- ${plugin}.rules
local function load_data_by_mysql(store, config)
    -- 查找enable
    local enables, err = store:query({
        sql = "select `key`, `value` from meta where `key` like \"%.enable\""
    })

    if err then
        ngx.log(ngx.ERR, "Load Meta Data error: ", err)
        os.exit(1)
    end

    if enables and type(enables) == "table" and #enables > 0 then
        for i, v in ipairs(enables) do
            orange_db.set(v.key, v.value == "1")
        end
    end

    local available_plugins = config.plugins
    for i, v in ipairs(available_plugins) do
        if v ~= "stat" then
            local rules, err = store:query({
                sql = "select `value` from " .. v .. " order by id asc"
            })

            if err then
                ngx.log(ngx.ERR, "Load Plugin Rules Data error: ", err)
                os.exit(1)
            end

            if rules and type(rules) == "table" and #rules > 0 then
                local format_rules = {}
                for i, v in ipairs(rules) do
                    table_insert(format_rules, cjson.decode(v.value))
                end
                orange_db.set_json(v .. ".rules", format_rules)
            end
        end
    end
end



-- ########################### Orange #############################
local Orange = {}

-- 执行过程:
-- 加载配置
-- 实例化存储store
-- 加载插件
-- 插件排序
function Orange.init(options)
    options = options or {}
    local store, config
    local status, err = pcall(function()
        local conf_file_path = options.config
        config = config_loader.load(conf_file_path)
        store = require("orange.store.mysql_store")(config.store_mysql)

        loaded_plugins = load_node_plugins(config, store)
        ngx.update_time()
        config.orange_start_at = ngx.now()
    end)

    if not status or err then
        ngx.log(ngx.ERR, "Startup error: " .. err)
        os.exit(1)
    end

    Orange.data = {
        store = store,
        config = config
    }

    for _, plugin in ipairs(loaded_plugins) do
        local tag = plugin.handler:get_tag()
        if bin32.ban(tag, base_plugin.TAGS.REDIRECT) then
            table_insert(redirect_plugins, plugin)
        end
        if bin32.ban(tag, base_plugin.TAGS.REWRITE) then
            table_insert(rewrite_plugins, plugin)
        end
        if bin32.ban(tag, base_plugin.TAGS.ACCESS) then
            table_insert(access_plugins, plugin)
        end
        if bin32.ban(tag, base_plugin.TAGS.HEADER_FILTER) then
            table_insert(header_filter_plugins, plugin)
        end
        if bin32.ban(tag, base_plugin.TAGS.BODAY_FILTER) then
            table_insert(body_filter_plugins, plugin)
        end
    end

    table_sort(redirect_plugins, plugin_priority_compare)
    table_sort(rewrite_plugins, plugin_priority_compare)
    table_sort(access_plugins, plugin_priority_compare)
    table_sort(header_filter_plugins, plugin_priority_compare)
    table_sort(body_filter_plugins, plugin_priority_compare)

    return config, store
end

function Orange.init_worker()
    -- 初始化定时器，清理计数器等
    if Orange.data and Orange.data.store and Orange.data.config.store == "mysql" then
        local worker_id = ngx.worker.id()
        if worker_id == 0 then
            local ok, err = ngx.timer.at(0, function(premature, store, config)
                load_data_by_mysql(store, config)
            end, Orange.data.store, Orange.data.config)
            if not ok then
                ngx.log(ngx.ERR, "failed to create the timer: ", err)
                return
            end
        end
    end

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_worker()
    end
end


function Orange.redirect()
    ngx.ctx.ORANGE_REDIRECT_START = now()

    for _, plugin in ipairs(redirect_plugins) do
        plugin.handler:redirect()
    end

    local now = now()
    ngx.ctx.ORANGE_REDIRECT_TIME = now - ngx.ctx.ORANGE_REDIRECT_START
    ngx.ctx.ORANGE_REDIRECT_ENDED_AT = now
end

function Orange.rewrite()
    ngx.ctx.ORANGE_REWRITE_START = now()

    for _, plugin in ipairs(rewrite_plugins) do
        plugin.handler:rewrite()
    end

    local now = now()
    ngx.ctx.ORANGE_REWRITE_TIME = now - ngx.ctx.ORANGE_REWRITE_START
    ngx.ctx.ORANGE_REWRITE_ENDED_AT = now
end


function Orange.access()
    ngx.ctx.ORANGE_ACCESS_START = now()

    for _, plugin in ipairs(access_plugins) do
        plugin.handler:access()
    end

    local now = now()
    ngx.ctx.ORANGE_ACCESS_TIME = now - ngx.ctx.ORANGE_ACCESS_START
    ngx.ctx.ORANGE_ACCESS_ENDED_AT = now
    ngx.ctx.ORANGE_PROXY_LATENCY = now - ngx.req.start_time() * 1000
    ngx.ctx.ACCESSED = true
end


function Orange.header_filter()

    if ngx.ctx.ACCESSED then
        local now = now()
        ngx.ctx.ORANGE_WAITING_TIME = now - ngx.ctx.ORANGE_ACCESS_ENDED_AT -- time spent waiting for a response from upstream
        ngx.ctx.ORANGE_HEADER_FILTER_STARTED_AT = now
    end

    for _, plugin in ipairs(header_filter_plugins) do
        plugin.handler:header_filter()
    end

    if ngx.ctx.ACCESSED then
        ngx.header[HEADERS.UPSTREAM_LATENCY] = ngx.ctx.ORANGE_WAITING_TIME
        ngx.header[HEADERS.PROXY_LATENCY] = ngx.ctx.ORANGE_PROXY_LATENCY
    end
end

function Orange.body_filter()
    for _, plugin in ipairs(body_filter_plugins) do
        plugin.handler:body_filter()
    end

    if ngx.ctx.ACCESSED then
        ngx.ctx.ORANGE_RECEIVE_TIME = now() - ngx.ctx.ORANGE_HEADER_FILTER_STARTED_AT
    end
end

function Orange.log()
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:log()
    end
end

return Orange
