local BaseAPI = require("orange.plugins.base_api")
local common_api = require("orange.plugins.common_api")
local plugin_config =  require("orange.plugins.rate_limiting_for_every_value.plugin")

local api = BaseAPI:new(plugin_config.api_name, 2)
api:merge_apis(common_api(plugin_config.table_name))
return api
