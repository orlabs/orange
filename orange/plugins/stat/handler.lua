local BasePlugin = require("orange.plugins.base")
local stat = require("orange.plugins.stat.stat")

local StatHandler = BasePlugin:extend()

StatHandler.PRIORITY = 2000

function StatHandler:new()
    StatHandler.super.new(self, "stat-plugin")
    stat.init()
end


function StatHandler:log(conf)
    StatHandler.super.log(self)
    stat.log()
end

return StatHandler