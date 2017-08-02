local BasePlugin = require("orange.plugins.base_handler")
local orange_db = require("orange.store.orange_db")
local balancer_execute = require("orange.utils.balancer").execute
local utils = require("orange.utils.utils")
local ngx_balancer = require "ngx.balancer"
local log = ngx.log

local get_last_failure = ngx_balancer.get_last_failure
local set_current_peer = ngx_balancer.set_current_peer
local set_timeouts     = ngx_balancer.set_timeouts
local set_more_tries   = ngx_balancer.set_more_tries

local function now()
    return ngx.now() * 1000
end

local BalancerHandler = BasePlugin:extend()
BalancerHandler.PRIORITY = 2000

function BalancerHandler:new(store)
    BalancerHandler.super.new(self, "Balancer-plugin")
    self.store = store
end

function BalancerHandler:balancer(conf)
    BalancerHandler.super.balancer(self)

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
    ngx.ctx.KONG_BALANCER_TIME = (ngx.ctx.KONG_BALANCER_TIME or 0) + try_latency
end

return BalancerHandler
