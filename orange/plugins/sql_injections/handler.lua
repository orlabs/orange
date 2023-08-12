local BasePlugin = require("orange.plugins.base_handler")
local json = require("orange.utils.json")
local sputils = require("orange.utils.sputils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local injection = require("orange.utils.injection")

local function filter_rules(sid, plugin, ngx_var_uri, params)

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
                -- log
                local handle = rule.handle
                if handle and handle.log == true then
                    ngx.log(ngx.ERR, "[SqlInjections] start handling: ", rule.id, ":", ngx_var_uri)
                end

                ngx.log(ngx.ERR, "==[SqlInjections][filter-res-2:", injection.sql("4 union select 1,1,version(),1"), "]")
                if handle.continue == true then
                else
                    return injection.sql(params) -- 不再匹配后续的规则
                end
            end
        end
    end

    return false
end


local SqlInjectionsHandler = BasePlugin:extend()
SqlInjectionsHandler.PRIORITY = 4998

function SqlInjectionsHandler:new(store)
    SqlInjectionsHandler.super.new(self, 'SqlInjectionsHandler-plugin')
    self.store = store
end

function SqlInjectionsHandler:access(conf)
    SqlInjectionsHandler.super.access(self)

    local enable = orange_db.get("sql_injections.enable")
    local meta = orange_db.get_json("sql_injections.meta")
    local selectors = orange_db.get_json("sql_injections.selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local params = sputils.getReqParamsStr(ngx)
    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.ERR, "==[SqlInjections][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "sql_injections")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.ERR, "[SqlInjections][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local filter_res = filter_rules(sid, "sql_injections", ngx_var_uri, params)
                -- true则拦截,false则继续
                if filter_res == true then
                    -- 不再执行此插件其他逻辑
                    -- 必须有print内容，否则只有exit不生效.
                    local res = json.encode({
                        code = 90001,
                        msg = "sql-injections - can not access!",
                        status = "fail"
                    })
                    ngx.print(res)
                    ngx.exit(ngx.OK)
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.ERR, "[SqlInjections][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end
        end
    end

end



return SqlInjectionsHandler
