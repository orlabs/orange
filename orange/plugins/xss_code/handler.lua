local BasePlugin = require("orange.plugins.base_handler")
local json = require("orange.utils.json")
local sputils = require("orange.utils.sputils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local injection = require("resty.injection")

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
                    ngx.log(ngx.ERR, "[XssCode] start handling: ", rule.id, ":", ngx_var_uri)
                end

                if handle.continue == true then
                else
                    return injection.xss(params) -- 不再匹配后续的规则
                end
            end
        end
    end

    return false
end


local XssCodeHandler = BasePlugin:extend()
XssCodeHandler.PRIORITY = 4997

function XssCodeHandler:new(store)
    XssCodeHandler.super.new(self, 'XssCodeHandler-plugin')
    self.store = store
end

function XssCodeHandler:access(conf)
    XssCodeHandler.super.access(self)

    local enable = orange_db.get("xss_code.enable")
    local meta = orange_db.get_json("xss_code.meta")
    local selectors = orange_db.get_json("xss_code.selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local params = sputils.getReqParamsStr(ngx)
    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.ERR, "==[XssCode][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "xss_code")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.ERR, "[XssCode][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local doFilter = filter_rules(sid, "xss_code", ngx_var_uri, params)
                --true则拦截,false则继续
                if doFilter == true then
                    -- 不再执行此插件其他逻辑
                    -- 必须有print内容，否则只有exit不生效.
                    local res = json.encode({
                        code = 90001,
                        msg = "xss-code - can not access!",
                        status = "fail"
                    })
                    ngx.print(res)
                    ngx.exit(ngx.OK)
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.ERR, "[XssCode][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end
        end
    end

end

return XssCodeHandler
