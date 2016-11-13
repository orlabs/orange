local ipairs = ipairs
local tonumber = tonumber
local string_find = string.find
local ngx_redirect = ngx.redirect
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")


local function filter_rules(sid, plugin, ngx_var_uri, ngx_var_host, ngx_var_scheme, ngx_var_args)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for j, rule in ipairs(rules) do
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, plugin)
            -- extract阶段
            local variables = extractor_util.extract_variables(rule.extractor)

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle and handle.url_tmpl then
                    local to_redirect = handle_util.build_url(rule.extractor.type, handle.url_tmpl, variables)
                    if to_redirect and to_redirect ~= ngx_var_uri then
                        local redirect_status = tonumber(handle.redirect_status)
                        if redirect_status ~= 301 and redirect_status ~= 302 then
                            redirect_status = 301
                        end

                        if string_find(to_redirect, 'http') ~= 1 then
                            to_redirect = ngx_var_scheme .. "://" .. ngx_var_host .. to_redirect
                        end

                        if ngx_var_args ~= nil then
                            if string_find(to_redirect, '?') then -- 不存在?，直接缀上url args
                                if handle.trim_qs ~= true then
                                    to_redirect = to_redirect .. "&" .. ngx_var_args
                                end
                            else
                                if handle.trim_qs ~= true then
                                    to_redirect = to_redirect .. "?" .. ngx_var_args
                                end
                            end
                        end

                        if handle.log == true then
                            ngx.log(ngx.ERR, "[Redirect] ", ngx_var_uri, " to:", to_redirect)
                        end

                        ngx_redirect(to_redirect, redirect_status)
                    end
                end

                return true
            end
        end
    end

    return false
end

local RedirectHandler = BasePlugin:extend()
RedirectHandler.PRIORITY = 2000

function RedirectHandler:new(store)
    RedirectHandler.super.new(self, "redirect-plugin")
    self.store = store
end

function RedirectHandler:redirect()
    RedirectHandler.super.redirect(self)

    local enable = orange_db.get("redirect.enable")
    local meta = orange_db.get_json("redirect.meta")
    local selectors = orange_db.get_json("redirect.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end
    
    local ngx_var = ngx.var
    local ngx_var_uri = ngx_var.uri
    local ngx_var_host = ngx_var.http_host
    local ngx_var_scheme = ngx_var.scheme
    local ngx_var_args = ngx_var.args

    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[Redirect][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "redirect")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Redirect][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "redirect", ngx_var_uri, ngx_var_host, ngx_var_scheme, ngx_var_args)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Redirect][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return RedirectHandler
