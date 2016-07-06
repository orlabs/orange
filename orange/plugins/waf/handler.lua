local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base")
local stat = require("orange.plugins.waf.stat")

local WAFHandler = BasePlugin:extend()
WAFHandler.PRIORITY = 2000

function WAFHandler:new(store)
    WAFHandler.super.new(self, "waf-plugin")
    self.store = store
end

function WAFHandler:access(conf)
    WAFHandler.super.access(self)

    local access_config = {
        enable = orange_db.get("waf.enable"),
        rules = orange_db.get_json("waf.rules")
    }

    if not access_config or access_config.enable ~= true then
        return
    end

    local rules = access_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end
    
    for i, rule in ipairs(rules) do
        local enable = rule.enable
        if enable == true then
            local judge = rule.judge
            local judge_type = judge.type
            local conditions = judge.conditions
            local pass = false
            if judge_type == 0 or judge_type == 1 then
                pass = judge_util.filter_and_conditions(conditions)
            elseif judge_type == 2 then
                pass = judge_util.filter_or_conditions(conditions)
            elseif judge_type == 3 then
                pass = judge_util.filter_complicated_conditions(judge.expression, conditions, self:get_name())
            end

            -- extract阶段
            local extractor = rule.extractor
            local extractions = extractor and extractor.extractions
            local variables
            if extractions then
                variables = extractor_util.extract(extractions)
            end


            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle.stat == true then
                    local key = rule.id -- rule.name .. ":" .. rule.id
                    stat.count(key, 1)
                end

                if handle.perform == 'allow' then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[WAF-Pass-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[WAF-Forbidden-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end
                    ngx.exit(tonumber(handle.code or 403))
                    return
                end
            end
        end
    end
end

return WAFHandler