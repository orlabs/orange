local BaseAPI = require("orange.plugins.base_api")
local common_api = require("orange.plugins.common_api")
local plugin_config =  require("orange.plugins.property_rate_limiting.plugin")

local api = BaseAPI:new(plugin_config.api_name, 2)
api:merge_apis(common_api(plugin_config.table_name))
return api
