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
local ngx_set_uri_args = ngx.req.set_uri_args
local ngx_decode_args = ngx.decode_args

local function ngx_set_uri(uri,rule_handle)
    ngx.var.upstream_scheme = rule_handle.upstream_scheme
    ngx.var.upstream_host = rule_handle.host or ngx.var.host
    ngx.var.upstream_url = rule_handle.upstream_name
    if uri then
        ngx.var.upstream_request_uri = uri  .. '?' .. ngx.encode_args(ngx.req.get_uri_args())
    end
    ngx.log(ngx.INFO, '[DynamicUpstream][upstream request][http://', ngx.var.upstream_url, ngx.var.upstream_request_uri, ']')
end

local function filter_rules(sid, plugin, ngx_var_uri)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")

    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            ngx.log(ngx.INFO, "==[DynamicUpstream][rule name:", rule.name, "][rule id:", rule.id, ']')
            -- judge阶段
            local pass = judge_util.judge_rule(rule, "dynamic_upstream")

            -- handle阶段
            if pass then
                -- extract阶段
                local variables = extractor_util.extract_variables(rule.extractor)

                local handle = rule.handle
                if not handle.uri_tmpl then
                    ngx_set_uri(nil, handle)
                elseif handle and handle.upstream_name then
                    local to_rewrite = handle_util.build_uri(rule.extractor.type, handle.uri_tmpl, variables)
                    if to_rewrite then
                        if handle.log == true then
                            ngx.log(ngx.INFO, "[DynamicUpstream] ", ngx_var_uri, " to:", to_rewrite)
                        end

                        local from, to, err = ngx_re_find(to_rewrite, "[?]{1}", "jo")

                        if not err and from and from >= 1 then
                            --local qs = ngx_re_sub(to_rewrite, "[A-Z0-9a-z-_/]*[%?]{1}", "", "jo")
                            local qs = string_sub(to_rewrite, from + 1)
                            if qs then
                                -- save original query params
                                -- ngx_set_uri_args(ngx.req.get_uri_args())
                                -- not use above just to keep the same behavior with nginx `rewrite` instruct
                                local args = ngx_decode_args(qs, 0)
                                if args then
                                    ngx_set_uri_args(args)
                                end
                            end

                            to_rewrite = string_sub(to_rewrite, 1, from - 1)
                        end
                        ngx_set_uri(to_rewrite, handle)
                        return true
                    end
                end

                return true
            end
        end
    end

    return false
end

local DynamicUpstreamHandler = BasePlugin:extend()
DynamicUpstreamHandler.PRIORITY = 2000

function DynamicUpstreamHandler:new(store)
    DynamicUpstreamHandler.super.new(self, "dynamic-upstream-plugin")
    self.store = store
end

function DynamicUpstreamHandler:rewrite(conf)
    DynamicUpstreamHandler.super.rewrite(self)

    local enable = orange_db.get("dynamic_upstream.enable")
    local meta = orange_db.get_json("dynamic_upstream.meta")
    local selectors = orange_db.get_json("dynamic_upstream.selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local ngx_var_uri = ngx.var.uri
    for i, sid in ipairs(ordered_selectors) do
        local selector = selectors[sid]
        ngx.log(ngx.INFO, "==[DynamicUpstream][START SELECTOR:", sid, ",NAME:",selector.name,']')
        if selector and selector.enable == true then
            local selector_pass
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "dynamic_upstream")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[DynamicUpstream][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "dynamic_upstream", ngx_var_uri)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[DynamicUpstream][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return DynamicUpstreamHandler
