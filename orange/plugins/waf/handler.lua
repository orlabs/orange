local pairs = pairs
local judge = require("orange.utils.judge")
local BasePlugin = require("orange.plugins.base")
local cjson = require("cjson")

local WAFHandler = BasePlugin:extend()
WAFHandler.PRIORITY = 2000

function WAFHandler:new(store)
    WAFHandler.super.new(self, "waf-plugin")
    self.store = store
end

function WAFHandler:access(conf)
    WAFHandler.super.access(self)
    local access_config = self.store:get_waf_config()

    if access_config.enable ~= true then
        return
    end

    local access_rules = access_config.access_rules
    for i, rule in pairs(access_rules) do
        local enable = rule.enable
        if enable == true then
            local matcher = rule.matcher
            local match_type = matcher.type
            local conditions = matcher.conditions
            local pass = false
            if match_type == 0 or match_type == 1 then
                pass = judge.filter_and_conditions(conditions)
            elseif match_type == 2 then
                pass = judge.filter_or_conditions(conditions)
            elseif match_type == 3 then
                pass = judge.filter_complicated_conditions(matcher.expression, conditions, self:get_name())
            end

            if pass then
                local action = rule.action
                if action.perform == 'allow' then
                    if action.log == true then
                        ngx.log(ngx.ERR, "[WAF-Pass-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end
                else
                    if action.log == true then
                        ngx.log(ngx.ERR, "[WAF-Forbidden-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end
                    ngx.exit(tonumber(action.code or 403))
                    return
                end
            end
        end
    end
end

return WAFHandler