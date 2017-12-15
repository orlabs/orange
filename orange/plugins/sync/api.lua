local BaseAPI = require("orange.plugins.base_api")
local common_api = require("orange.plugins.common_api")

local api = BaseAPI:new("sync-api", 2)
api:merge_apis(common_api(plugin_config.table_name))
return api
