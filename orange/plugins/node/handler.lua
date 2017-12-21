local orange_db = require("orange.store.orange_db")
local BasePlugin = require("orange.plugins.base_handler")
local node = require("orange.plugins.node.node")

local NodeHandler = BasePlugin:extend()
NodeHandler.PRIORITY = 2000

function NodeHandler:new(store)
    NodeHandler.super.new(self, "node-plugin")
    self.store = store
end

function NodeHandler:init_worker(conf)

end

function NodeHandler:log(conf)
    node.log()
end

return NodeHandler
