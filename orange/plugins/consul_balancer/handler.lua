local BasePlugin = require("orange.plugins.base_handler")
local orange_db = require("orange.store.orange_db")
local utils = require("orange.utils.utils")

local orange = require("orange.orange")

local consul = require("orange.plugins.consul_balancer.consul_balancer")


local string_find = string.find

local ConsulBalancerHandler = BasePlugin:extend()
-- set balancer priority to 999 so that balancer's access will be called at last
ConsulBalancerHandler.PRIORITY = 999

function ConsulBalancerHandler:new(store)
    ConsulBalancerHandler.super.new(self, "ConsulBalancer-plugin")
    self.store = store
end

function ConsulBalancerHandler:db_ready()
    local enable = orange_db.get("consul_balancer.enable")
    local meta = orange_db.get_json("consul_balancer.meta")
    local selectors = orange_db.get_json("consul_balancer.selectors")
    
    if not enable or enable ~= true or not meta or not selectors then
        --ngx.var.target = ngx.var.upstream_url
        ngx.log(ngx.ERR,"end<<<<<<<<")
        return
    end

    local services = {}
    if type(selectors) == "table" then
        for k, v in pairs(selectors) do
            local id = nil
            if v and type(v) == "table" then
                for k1, upstream in pairs(v) do
                    if k1 == "id" then
                        id = upstream
                    end

                    if k1 == "service" then
                        table.insert( services, {
                            id = id,
                            name = upstream,
                            service = upstream,
                            tag = nil
                          } )
                    end
                end
            end
        end

        if #services > 0 then
            orange.data.consul.watch(services)
            ngx.log(ngx.INFO, "<<<<will watch ", #services)
        end
    end
end

function make_cache()
    local enable = orange_db.get("consul_balancer.enable")
    local meta = orange_db.get_json("consul_balancer.meta")
    local selectors = orange_db.get_json("consul_balancer.selectors")

    if not enable or enable ~= true or not meta or not selectors then
        ngx.log(ngx.DEBUG,"nil upstream_url,maybe disable")
        ngx.var.target = ngx.var.upstream_url
        return
    end

    ngx.ctx.consul_balancer_enable = true
    if not ngx.var.upstream_url or ngx.var.upstream_url == "nil" then
        ngx.var.target = ngx.var.upstream_url
        ngx.log(ngx.DEBUG,"nil upstream_url,maybe rediected")
        return
    end

    local upstream_url = ngx.var.upstream_url

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

    --ngx.log(ngx.INFO, "[scheme] ", scheme, "; [hostname] ", hostname, " [upstream_url] ", upstream_url)

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
                if name == upstream.service then
                    -- set target to orange_upstream
                    target = "http://orange_upstream"

                    -- set balancer_addr
                    balancer_addr = {
                        type                = "name",
                        id                  = upstream.id,
                        name                = name,
                        service             = upstream.service,
                    }

                    break
                end
            end -- end for loop
        end
    end

    if balancer_addr then
        ngx.ctx.consul_balancer_address = balancer_addr
    end

    -- target is used by proxy_pass
    ngx.var.target = target

    ngx.log(ngx.INFO, "[scheme] ", scheme, "; [hostname] ", hostname, "[target] ", target, "; [upstream_url] ", upstream_url)
end

function ConsulBalancerHandler:access(conf)
    ConsulBalancerHandler.super.access(self)

    make_cache()
end

function ConsulBalancerHandler:balancer(conf)
    ConsulBalancerHandler.super.balancer(self)

    if not ngx.ctx.consul_balancer_enable or ngx.ctx.consul_balancer_enable ~= true then
        --ngx.log(ngx.ERR, "balancer but ", ngx.ctx.consul_balancer_enable)
        return
    end

    orange.data.consul.round_robin(ngx.ctx.consul_balancer_address)
end

return ConsulBalancerHandler
