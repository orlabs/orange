local BaseAPI = require("orange.plugins.base_api")
local common_api = require("orange.plugins.common_api")
local table_insert = table.insert
local stat = require("orange.plugins.waf.stat")

local api = BaseAPI:new("waf-api", 2)

api:merge_apis(common_api("waf"))

api:get("/waf/stat", function(store)
    return function(req, res, next)
        local max_count = req.query.max_count or 500
        local stats = stat.get_all(max_count)

        local statistics = {}
        for i, s in ipairs(stats) do
            local tmp = {
                rule_id = s.rule_id,
                count = s.count,
            }
            table_insert(statistics, tmp)
        end

        local result = {
            success = true,
            data = {
                statistics = statistics
            }   
        }

        res:json(result)
    end
end)

return api
