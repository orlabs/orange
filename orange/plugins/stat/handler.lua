local BasePlugin = require("orange.plugins.base_handler")
local stat = require("orange.plugins.stat.stat")

local StatHandler = BasePlugin:extend()

StatHandler.PRIORITY = 2000

function StatHandler:new()
    StatHandler.super.new(self, "stat-plugin")
end

-- TODO init_worker_by_lua 是在 Nginx worker 进程启动后执行的 Lua 代码块。在这个环境中，不允许进行一些操作，如发起网络请求、操作文件系统等
--function StatHandler:init_worker(conf)
--    stat.init()
--end

function StatHandler:access(conf)
    StatHandler.super.access(self)
    stat.log()
end

return StatHandler
