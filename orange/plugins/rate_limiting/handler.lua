local ipairs = ipairs
local type = type
local tostring = tostring

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local BasePlugin = require("orange.plugins.base_handler")
local counter = require("orange.plugins.rate_limiting.counter")

local function get_current_stat(limit_key)
    return counter.get(limit_key)
end

local function incr_stat(limit_key, limit_type)
    counter.incr(limit_key, 1, limit_type)
end

local function get_limit_type(period)
    if not period then return nil end

    if period == 1 then
        return "Second"
    elseif period == 60 then
        return "Minute"
    elseif period == 3600 then
        return "Hour"
    elseif period == 86400 then
        return "Day"
    else
        return nil
    end
end


local RateLimitingHandler = BasePlugin:extend()
RateLimitingHandler.PRIORITY = 1000

function RateLimitingHandler:new(store)
    RateLimitingHandler.super.new(self, "rate-limiting-plugin")
    self.store = store
end

function RateLimitingHandler:access(conf)
    RateLimitingHandler.super.access(self)
    
    local rate_limiting_config = {
        enable = orange_db.get("rate_limiting.enable"),
        rules = orange_db.get_json("rate_limiting.rules")
    }
    if not rate_limiting_config or rate_limiting_config.enable ~= true then
        return
    end
    local rules = rate_limiting_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end

    local ngx_var = ngx.var
    for i, rule in ipairs(rules) do
        local enable = rule.enable
        if enable == true then
            -- judge阶段
            local judge = rule.judge
            local judge_type = judge.type
            local conditions = judge.conditions
            local pass = false
            if judge_type == 0 or judge_type == 1 then
                pass = judge_util.filter_and_conditions(conditions)
            elseif judge_type == 2 then
                pass = judge_util.filter_or_conditions(conditions)
            elseif judge_type == 3 then
                pass = judge_util.filter_complicated_conditions(judge.expression, conditions)
            end

            -- handle阶段
            local handle = rule.handle
            if pass then
                local limit_type = get_limit_type(handle.period)

                -- only work for valid limit type(1 second/minute/hour/day)
                if limit_type then
                    local current_timetable = utils.current_timetable()
                    local time_key = current_timetable[limit_type]
                    local limit_key = rule.id .. "#" .. time_key
                    local current_stat = get_current_stat(limit_key) or 0
                        
                    ngx.header["X-RateLimit-Limit" .. "-" .. limit_type] = handle.count

                    if current_stat >= handle.count then
                        if handle.log == true then
                            ngx.log(ngx.INFO, "[RateLimiting-Forbidden-Rule] ", rule.name, " uri:", ngx_var.uri, " limit:", handle.count, " reached:", current_stat, " remaining:", 0)
                        end

                        ngx.header["X-RateLimit-Remaining" .. "-" .. limit_type] = 0
                        return ngx.exit(429)
                    else
                        ngx.header["X-RateLimit-Remaining" .. "-" .. limit_type] = handle.count - current_stat - 1
                        incr_stat(limit_key, limit_type)

                        -- only for test, comment it in production
                        -- if handle.log == true then
                        --     ngx.log(ngx.INFO, "[RateLimiting-Rule] ", rule.name, " uri:", ngx_var.uri, " limit:", handle.count, " reached:", current_stat + 1)
                        -- end
                    end
                end
            end -- end `pass`

        end -- end `enable`
    end -- end for
end

return RateLimitingHandler
