local BasePlugin = require("orange.plugins.base_handler")
local orange_db = require("orange.store.orange_db")
local balancer_execute = require("orange.utils.balancer").execute
local utils = require("orange.utils.utils")
local ngx_balancer = require "ngx.balancer"
local string_find = string.find

local get_last_failure = ngx_balancer.get_last_failure
local set_current_peer = ngx_balancer.set_current_peer
local set_timeouts     = ngx_balancer.set_timeouts
local set_more_tries   = ngx_balancer.set_more_tries

local function now()
    return ngx.now() * 1000
end

local BalancerHandler = BasePlugin:extend()
-- set balancer priority to 999 so that balancer's access will be called at last
BalancerHandler.PRIORITY = 999

function BalancerHandler:new(store)
    BalancerHandler.super.new(self, "Balancer-plugin")
    self.store = store
end

function BalancerHandler:access(conf)
    BalancerHandler.super.access(self)

    local enable = orange_db.get("balancer.enable")
    local meta = orange_db.get_json("balancer.meta")
    local selectors = orange_db.get_json("balancer.selectors")

    if not enable or enable ~= true or not meta or not selectors then
        ngx.var.target = ngx.var.upstream_url
        return
    end
    local upstream_url = ngx.var.upstream_url
    ngx.log(ngx.INFO, "[upstream_url] ", upstream_url)

    -- set ngx.var.target
    local target = upstream_url
    local schema, hostname
    local balancer_addr
    if string_find(upstream_url, "://") then
        schema, hostname = upstream_url:match("^(.+)://(.+)$")
    else
        schema = "http"
        hostname = upstream_url
    end

    ngx.log(ngx.INFO, "[scheme] ", scheme, "; [hostname] ", hostname)

    -- check whether the hostname stored in db
    if utils.hostname_type(hostname) == "name" then
        local upstreams = selectors

        local name, port
        if string_find(hostname, ":") then
            name, port = hostname:match("^(.-)%:*(%d*)$")
        else
            name, port = hostname, 80
        end
        if upstreams and type(upstreams) == "table" then
            for _, upstream in pairs(upstreams) do
                if name == upstream.name then
                    -- set target to orange_upstream
                    target = "http://orange_upstream"

                    -- set balancer_addr
                    balancer_addr = {
                        type               = "name",
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
    if balancer_addr then
        local ok, err = balancer_execute(balancer_addr)
        if not ok then
            return ngx.exit(503)
        end
        ngx.ctx.balancer_address = balancer_addr
    end

    -- target is used by proxy_pass
    ngx.var.target = target

    ngx.log(ngx.INFO, "[target] ", target, "; [upstream_url] ", upstream_url)
end

function BalancerHandler:balancer(conf)
    BalancerHandler.super.balancer(self)

    local enable = orange_db.get("balancer.enable")
    if not enable or enable ~= true then
        return
    end

    local addr = ngx.ctx.balancer_address
    local tries = addr.tries
    local current_try = {}
    addr.try_count = addr.try_count + 1
    tries[addr.try_count] = current_try
    current_try.balancer_start = now()

    if addr.try_count > 1 then
        -- only call balancer on retry, first one is done in `access` which runs
        -- in the ACCESS context and hence has less limitations than this BALANCER
        -- context where the retries are executed

        -- record faliure data
        local previous_try = tries[addr.try_count - 1]
        previous_try.state, previous_try.code = get_last_failure()

        local ok, err = balancer_execute(addr)
        if not ok then
            ngx.log(ngx.ERR, "failed to retry the dns/balancer resolver for ",
                    addr.host, "' with: ", tostring(err))
            return ngx.exit(500)
        end

    else
        -- first try, so set the max number of retries
        local retries = addr.retries
        if retries > 0 then
            set_more_tries(retries)
        end
    end

    current_try.ip   = addr.ip
    current_try.port = addr.port

    -- set the targets as resolved
    local ok, err = set_current_peer(addr.ip, addr.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to set the current peer (address: ",
                tostring(addr.ip), " port: ", tostring(addr.port), "): ",
                tostring(err))
        return ngx.exit(500)
    end

    ok, err = set_timeouts(addr.connection_timeout / 1000,
                           addr.send_timeout / 1000,
                           addr.read_timeout /1000)
    if not ok then
        ngx.log(ngx.ERR, "could not set upstream timeouts: ", err)
    end

    -- record try-latency
    local try_latency = now() - current_try.balancer_start
    current_try.balancer_latency = try_latency
    current_try.balancer_start = nil

    -- record overall latency
    ngx.ctx.ORANGE_BALANCER_TIME = (ngx.ctx.ORANGE_BALANCER_TIME or 0) + try_latency
end

return BalancerHandler
