local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local string_find = string.find
local pcall = pcall
local require = require
require("orange.lib.globalpatches")()
local ck = require("orange.lib.cookie")
local utils = require("orange.utils.utils")
local config_loader = require("orange.utils.config_loader")
local dao = require("orange.store.dao")
local ngx_balancer = require("ngx.balancer")
local orange_db = require("orange.store.orange_db")
local balancer_execute = require("orange.utils.balancer").execute
local dns_client = require("resty.dns.client")

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

    -- init dns_client
    assert(dns_client.init())

    return config, store
end

function Orange.init_worker()
    -- 仅在 init_worker 阶段调用，初始化随机因子，仅允许调用一次
    math.randomseed()
    -- 初始化定时器，清理计数器等
    if Orange.data and Orange.data.store and Orange.data.config.store == "mysql" then
        local worker_id = ngx.worker.id()
        if worker_id == 0 then
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
    end

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_worker()
    end
end

function Orange.init_cookies()
    ngx.ctx.__cookies__ = nil

    local COOKIE, err = ck:new()
    if not err and COOKIE then
        ngx.ctx.__cookies__ = COOKIE
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

    local upstream_url = ngx.var.upstream_url
    ngx.log(ngx.INFO, "[AFTER ACCESS] ", " upstream_url: " , upstream_url)

    -- here we set the ngx.var.target
    local target = upstream_url
    local scheme, hostname
    local balancer_address
    if string_find(upstream_url, "://") then
        scheme, hostname = upstream_url:match("^(.+)://(.+)$")
    else
        schema = "http"
        hostname = upstream_url
    end

    ngx.log(ngx.INFO, "[scheme] ", scheme, "; [hostname] ", hostname)

    -- only care about upstreams stored in db
    if utils.hostname_type(hostname) == "name" then
        local upstreams = orange_db.get_json("balancer.selectors")

        local name, port
        if string_find(hostname, ":") then
            name, port = hostname:match("^(.-)%:*(%d*)$")
        else
            name, port = hostname, 80
        end

        if upstreams and type(upstreams) == "table" then
            for _, upstream in pairs(upstreams) do
                if name == upstream.name then
                    target = "http://orange_upstream"

                    -- set balancer_address
                    balancer_address = {
                        type               = "name",  -- must be name
                        host               = name,
                        port               = port,
                        try_count          = 0,
                        tries              = {},
                        retries            = upstream.retries or 0, -- number of retries for the balancer
                        connection_timeout = upstream.connection_timeout or 60000,
                        send_timeout       = upstream.send_timeout or 60000,
                        read_timeout       = upstream.read_timeout or 60000,
                        -- ip              = nil,     -- final target IP address
                        -- balancer        = nil,     -- the balancer object, in case of balancer
                        -- hostname        = nil,     -- the hostname belonging to the final target IP
                    }

                    break
                end
            end -- end for loop
        end
    end

    -- run balancer_execute once before the `balancer` context
    if balancer_address then
        local ok, err = balancer_execute(balancer_address)
        if not ok then
            return ngx.exit(503)
        end
        ngx.ctx.balancer_address = balancer_address
    end

    -- target is used by proxy_pass
    ngx.var.target = target

    ngx.log(ngx.INFO, "[target] ", target, "; [upstream_url] ", upstream_url)

    local now_time = now()
    ngx.ctx.ORANGE_ACCESS_TIME = now_time - ngx.ctx.ORANGE_ACCESS_START
    ngx.ctx.ORANGE_ACCESS_ENDED_AT = now_time
    ngx.ctx.ORANGE_PROXY_LATENCY = now_time - ngx.req.start_time() * 1000
    ngx.ctx.ACCESSED = true
end

function Orange.balancer()
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:balancer()
    end
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
