--
-- Created by IntelliJ IDEA.
-- User: soul11201
-- Date: 2017/3/14
-- Time: 9:10
-- To change this template use File | Settings | File Templates.
--

local BasePlugin = require("orange.plugins.base_handler")
local hc = require "resty.upstream.healthcheck"

local UpstreamMonitor = BasePlugin:extend()
local plug_name = 'upstream_monitor'
UpstreamMonitor.PRIORITY = 2000

function UpstreamMonitor:new(store)
    self.super:new(plug_name)
end

function UpstreamMonitor:init_worker()
    self.super:init_worker()
    local ok, err = hc.spawn_checker{
        shm = "healthcheck",  -- defined by "lua_shared_dict"
        upstream = "default_upstream", -- defined by "upstream"
        type = "http",

        http_req = "GET /status HTTP/1.0\r\nHost: localhost\r\n\r\n",
        -- raw HTTP request for checking

        interval = 3000,  -- run the check cycle every 2 sec
        timeout = 1000,   -- 1 sec is the timeout for network operations
        fall = 3,  -- # of successive failures before turning a peer down
        rise = 2,  -- # of successive successes before turning a peer up
        valid_statuses = {200, 302},  -- a list valid HTTP status code
        concurrency = 10,  -- concurrency level for test requests
        shared_config=true,
    }

    if not ok then
        ngx.log(ngx.ERR, "failed to spawn health checker: ", err)
        return
    end

    -- Just call hc.spawn_checker() for more times here if you have
    -- more upstream groups to monitor. One call for one upstream group.
    -- They can all share the same shm zone without conflicts but they
    -- need a bigger shm zone for obvious reasons.
end


return UpstreamMonitor



