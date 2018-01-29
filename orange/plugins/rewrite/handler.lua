local pairs = pairs
local ipairs = ipairs
local ngx_re_sub = ngx.re.sub
local ngx_re_find = ngx.re.find
local string_sub = string.sub
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")
local ngx_set_uri = ngx.req.set_uri
local ngx_set_uri_args = ngx.req.set_uri_args
local ngx_decode_args = ngx.decode_args


local function filter_rules(sid, plugin, ngx_var_uri)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, "rewrite")
            -- extract阶段
            local variables = extractor_util.extract_variables(rule.extractor)

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle and handle.uri_tmpl then
                    local to_rewrite = handle_util.build_uri(rule.extractor.type, handle.uri_tmpl, variables)
                    if to_rewrite and to_rewrite ~= ngx_var_uri then
                        if handle.log == true then
                            ngx.log(ngx.INFO, "[Rewrite] ", ngx_var_uri, " to:", to_rewrite)
                        end

                        local from, to, err = ngx_re_find(to_rewrite, "[%?]{1}", "jo")
                        if not err and from and from >= 1 then
                            --local qs = ngx_re_sub(to_rewrite, "[A-Z0-9a-z-_/]*[%?]{1}", "", "jo")
                            local qs = string_sub(to_rewrite, from+1)
                            if qs then
                                local args = ngx_decode_args(qs, 0)
                                if args then 
                                    ngx_set_uri_args(args) 
                                end
                            end
                        end
                        ngx_set_uri(to_rewrite, true)
                    end
                end

                return true
            end
        end
    end

    return false
end

local RewriteHandler = BasePlugin:extend()
RewriteHandler.PRIORITY = 2000

function RewriteHandler:new(store)
    RewriteHandler.super.new(self, "rewrite-plugin")
    self.store = store
end

function RewriteHandler:rewrite(conf)
    RewriteHandler.super.rewrite(self)

    local enable = orange_db.get("rewrite.enable")
    local meta = orange_db.get_json("rewrite.meta")
    local selectors = orange_db.get_json("rewrite.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[Rewrite][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "rewrite")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Rewrite][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "rewrite", ngx_var_uri)
                local selector_continue = selector.handle and selector.handle.continue
                if stop or not selector_continue then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Rewrite][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end
        end
    end
end

return RewriteHandler
