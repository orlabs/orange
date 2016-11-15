local server = require("dashboard.server")
-- global context
local srv = server:new(context.config, context.store, context.views_path)
return srv:get_app()
