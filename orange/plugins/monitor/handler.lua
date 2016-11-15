local ipairs = ipairs
local orange_db = require("orange.store.orange_db")
local stat = require("orange.plugins.monitor.stat")
local judge_util = require("orange.utils.judge")
local BasePlugin = require("orange.plugins.base_handler")


local function filter_rules(sid, plugin, ngx_var_uri)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, plugin)

            -- handle阶段
            if pass then
                local key_suffix =  rule.id
                stat.count(key_suffix)

                local handle = rule.handle
                if handle then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[Monitor] ", rule.id, ":", ngx_var_uri)
                    end

                    if handle.continue == true then
                    else
                        return true -- 不再匹配后续的规则，即不再统计满足后续规则的监控
                    end
                end
            end
        end
    end

    return false
end


local URLMonitorHandler = BasePlugin:extend()
URLMonitorHandler.PRIORITY = 2000

function URLMonitorHandler:new(store)
    URLMonitorHandler.super.new(self, "monitor-plugin")
    self.store = store
end

function URLMonitorHandler:log(conf)
    URLMonitorHandler.super.log(self)

    local enable = orange_db.get("monitor.enable")
    local meta = orange_db.get_json("monitor.meta")
    local selectors = orange_db.get_json("monitor.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end
    
    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[Monitor][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "monitor")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Monitor][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "monitor", ngx_var_uri)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Monitor][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end

            -- if continue or break the loop
            if selector.handle and selector.handle.continue == true then
                -- continue next selector
            else
                break
            end
        end
    end
    
end


return URLMonitorHandler
