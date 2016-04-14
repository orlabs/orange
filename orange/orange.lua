local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort

local utils = require "orange.utils.utils"
local config_loader = require "orange.utils.config_loader"
local logger = require("orange.utils.logger")


local HEADERS = {
    PROXY_LATENCY = "X-Orange-Proxy-Latency",
    UPSTREAM_LATENCY = "X-Orange-Upstream-Latency",
}

local loaded_plugins = {}

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

    table_sort(sorted_plugins, function(a, b)
        local priority_a = a.handler.PRIORITY or 0
        local priority_b = b.handler.PRIORITY or 0
        return priority_a > priority_b
    end)

    return sorted_plugins
end

-- ms
local function now()
    return ngx.now() * 1000
end

---
-- modified usage: the origin is from `Kong`
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
        local store_type = config.store
        
        if store_type == "file" then
            store = require("orange.store.file_store")({
                file_path = config.store_file.path
            })
        elseif store_type == "redis" then
            store = require("orange.store.redis_store")()
        elseif store_type == "mysql" then
            store = require("orange.store.mysql_store")()
        end


        loaded_plugins = load_node_plugins(config, store)
        ngx.update_time()
        config.orange_start_at = ngx.now()
    end)
    if not status or err then
        ngx.log(ngx.ERR, "Startup error: " .. err)
        os.exit(1)
    end

    return config, store
end

function Orange.init_worker()
    -- 初始化定时器
    -- 清理计数器

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_worker()
    end
end


function Orange.redirect()
    ngx.ctx.ORANGE_REDIRECT_START = now()

    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins, true) do
        plugin.handler:redirect(plugin_conf)
    end

    local now = now()
    ngx.ctx.ORANGE_REDIRECT_TIME = now - ngx.ctx.ORANGE_REDIRECT_START
    ngx.ctx.ORANGE_REDIRECT_ENDED_AT = now
end

function Orange.rewrite()
    ngx.ctx.ORANGE_REWRITE_START = now()

    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins, true) do
        plugin.handler:rewrite(plugin_conf)
    end

    local now = now()
    ngx.ctx.ORANGE_REWRITE_TIME = now - ngx.ctx.ORANGE_REWRITE_START
    ngx.ctx.ORANGE_REWRITE_ENDED_AT = now
end


function Orange.access()
    ngx.ctx.ORANGE_ACCESS_START = now()

    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins, true) do
        plugin.handler:access(plugin_conf)
    end

    local now = now()
    ngx.ctx.ORANGE_ACCESS_TIME = now - ngx.ctx.ORANGE_ACCESS_START
    ngx.ctx.ORANGE_ACCESS_ENDED_AT = now
    ngx.ctx.ORANGE_PROXY_LATENCY = now - ngx.req.start_time() * 1000
    ngx.ctx.ACCESSED = true
end


function Orange.header_filter()

    if ngx.ctx.ACCESSED  then
        local now = now()
        ngx.ctx.ORANGE_WAITING_TIME = now - ngx.ctx.ORANGE_ACCESS_ENDED_AT -- time spent waiting for a response from upstream
        ngx.ctx.ORANGE_HEADER_FILTER_STARTED_AT = now
    end

    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins) do
        plugin.handler:header_filter(plugin_conf)
    end

    if ngx.ctx.ACCESSED then
        ngx.header[HEADERS.UPSTREAM_LATENCY] = ngx.ctx.ORANGE_WAITING_TIME
        ngx.header[HEADERS.PROXY_LATENCY] = ngx.ctx.ORANGE_PROXY_LATENCY
    end
end

function Orange.body_filter()
    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins) do
        plugin.handler:body_filter(plugin_conf)
    end

    if ngx.ctx.ACCESSED then
        ngx.ctx.ORANGE_RECEIVE_TIME = now() - ngx.ctx.ORANGE_HEADER_FILTER_STARTED_AT
    end
end

function Orange.log()
    for plugin, plugin_conf in iter_plugins_for_req(loaded_plugins) do
        plugin.handler:log(plugin_conf)
    end

    -- stat_plugin.log()
end

return Orange