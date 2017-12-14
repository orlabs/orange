local ipairs = ipairs
local type = type
local tostring = tostring
local table_concat = table.concat;

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local BasePlugin = require("orange.plugins.base_handler")
local plugin_config =  require("orange.plugins.property_rate_limiting.plugin")
local counter = require("orange.plugins.property_rate_limiting.counter")
local extractor_util = require("orange.utils.extractor")

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

local function filter_rules(sid, plugin, ngx_var_uri)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            local real_value = table_concat( extractor_util.extract_variables(rule.extractor),"#")
            local pass = (real_value ~= '');

            -- handle阶段
            local handle = rule.handle
            if pass then
                local limit_type = get_limit_type(handle.period)

                -- only work for valid limit type(1 second/minute/hour/day)
                if limit_type then
                    local current_timetable = utils.current_timetable()
                    local time_key = current_timetable[limit_type]
                    local limit_key = rule.id .. "#" .. time_key .. "#" .. real_value
                    local current_stat = get_current_stat(limit_key) or 0

                    ngx.header[plugin_config.plug_reponse_header_prefix .. limit_type] = handle.count

                    if current_stat >= handle.count then
                        if handle.log == true then
                            ngx.log(ngx.INFO, plugin_config.message_forbidden, rule.name, " uri:", ngx_var_uri, " limit:", handle.count, " reached:", current_stat, " remaining:", 0)
                        end

                        ngx.header[plugin_config.plug_reponse_header_prefix ..limit_type] = 0
                        ngx.exit(429)
                        return true
                    else
                        ngx.header[plugin_config.plug_reponse_header_prefix ..limit_type] = handle.count - current_stat - 1
                        incr_stat(limit_key, limit_type)

                        -- only for test, comment it in production
                        -- if handle.log == true then
                        --     ngx.log(ngx.INFO, "[RateLimiting-Rule] ", rule.name, " uri:", ngx_var_uri, " limit:", handle.count, " reached:", current_stat + 1)
                        -- end
                    end
                end
            end -- end `pass`

        end -- end `enable`
    end -- end for

    return false
end


local PropertyRateLimitingHandler = BasePlugin:extend()
PropertyRateLimitingHandler.PRIORITY = 1000

function PropertyRateLimitingHandler:new(store)
    PropertyRateLimitingHandler.super.new(self, plugin_config.name)
    self.store = store
end

function PropertyRateLimitingHandler:access(conf)
    PropertyRateLimitingHandler.super.access(self)

    local enable = orange_db.get(plugin_config.table_name..".enable")
    local meta = orange_db.get_json(plugin_config.table_name..".meta")
    local selectors = orange_db.get_json(plugin_config.table_name..".selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[",plugin_config.name_for_log,"][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass
            local selector_continue = selector.handle and selector.handle.continue
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector,plugin_config.table_name)-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[",plugin_config.name_for_log,"][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, plugin_config.table_name, ngx_var_uri)
                if stop or not selector_continue then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[",plugin_config.name_for_log,"][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end
        end
    end

end

return PropertyRateLimitingHandler
