local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local pcall = pcall
local require = require
require("orange.lib.globalpatches")()
local utils = require("orange.utils.utils")
local config_loader = require("orange.utils.config_loader")
local dao = require("orange.store.dao")

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
            ngx.log(ngx.WARN, "The following plugin is not installed or has no handler: " .. v)
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

    return config, store
end

function Orange.init_worker()
    -- 仅在 init_worker 阶段调用，初始化随机因子，仅允许调用一次
    math.randomseed()
    -- 初始化定时器，清理计数器等
    if Orange.data and Orange.data.store and Orange.data.config.store == "mysql" then
            local ok, err = ngx.timer.at(0, function(premature, store, config)
                local available_plugins = config.plugins
                for _, v in ipairs(available_plugins) do
                    local load_success = dao.load_data_by_mysql(store, v)
                    if not load_success then
                        os.exit(1)
                    end
                end
            end, Orange.data.store, Orange.data.config)

            if not ok then
                ngx.log(ngx.ERR, "failed to create the timer: ", err)
                return os.exit(1)
            end
    end

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_worker()
    end
end


function Orange.redirect()
    ngx.ctx.ORANGE_REDIRECT_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:redirect()
    end

    local now_time = now()
    ngx.ctx.ORANGE_REDIRECT_TIME = now_time - ngx.ctx.ORANGE_REDIRECT_START
    ngx.ctx.ORANGE_REDIRECT_ENDED_AT = now_time
end

function Orange.rewrite()
    ngx.ctx.ORANGE_REWRITE_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:rewrite()
    end

    local now_time = now()
    ngx.ctx.ORANGE_REWRITE_TIME = now_time - ngx.ctx.ORANGE_REWRITE_START
    ngx.ctx.ORANGE_REWRITE_ENDED_AT = now_time
end


function Orange.access()
    ngx.ctx.ORANGE_ACCESS_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:access()
    end

    local now_time = now()
    ngx.ctx.ORANGE_ACCESS_TIME = now_time - ngx.ctx.ORANGE_ACCESS_START
    ngx.ctx.ORANGE_ACCESS_ENDED_AT = now_time
    ngx.ctx.ORANGE_PROXY_LATENCY = now_time - ngx.req.start_time() * 1000
    ngx.ctx.ACCESSED = true
end


function Orange.header_filter()

    if ngx.ctx.ACCESSED then
        local now_time = now()
        ngx.ctx.ORANGE_WAITING_TIME = now_time - ngx.ctx.ORANGE_ACCESS_ENDED_AT -- time spent waiting for a response from upstream
        ngx.ctx.ORANGE_HEADER_FILTER_STARTED_AT = now_time
    end

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:header_filter()
    end

    if ngx.ctx.ACCESSED then
        ngx.header[HEADERS.UPSTREAM_LATENCY] = ngx.ctx.ORANGE_WAITING_TIME
        ngx.header[HEADERS.PROXY_LATENCY] = ngx.ctx.ORANGE_PROXY_LATENCY
    end
end

function Orange.body_filter()
    for _, plugin in ipairs(loaded_plugins) do
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
