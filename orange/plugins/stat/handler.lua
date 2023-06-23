local BasePlugin = require("orange.plugins.base_handler")
local stat = require("orange.plugins.stat.stat")

local StatHandler = BasePlugin:extend()

StatHandler.PRIORITY = 2000

function StatHandler:new()
    StatHandler.super.new(self, "stat-plugin")
end

function StatHandler:init_worker(conf)
    stat.init()
end

function StatHandler:log(conf)
    stat.log()
end

return StatHandler
