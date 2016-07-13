local pairs = pairs
local ipairs = ipairs
local string_len = string.len
local string_find = string.find
local ngx_re_gsub = ngx.re.gsub
local ngx_redirect = ngx.redirect
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base")


local RedirectHandler = BasePlugin:extend()
RedirectHandler.PRIORITY = 2000

function RedirectHandler:new(store)
    RedirectHandler.super.new(self, "redirect-plugin")
    self.store = store
end

function RedirectHandler:redirect()
    RedirectHandler.super.redirect(self)

    local redirect_config = {
        enable = orange_db.get("redirect.enable"),
        rules = orange_db.get_json("redirect.rules")
    }
    
    if not redirect_config or redirect_config.enable ~= true then
        return
    end

    local ngx_var = ngx.var
    local ngx_var_uri = ngx_var.uri
    local ngx_var_host = ngx_var.http_host
    local ngx_var_scheme = ngx_var.scheme

    local rules = redirect_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end
    
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
                pass = judge_util.filter_complicated_conditions(judge.expression, conditions, self:get_name())
            end

            -- extract阶段
            local extractor = rule.extractor
            local extractor_type = extractor.type
            local extractions = extractor and extractor.extractions
            local variables
            if extractions then
                variables = extractor_util.extract(extractor_type, extractions)
            end

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle and handle.url_tmpl then
                    local to_redirect = handle_util.build_url(extractor_type, handle.url_tmpl, variables, self:get_name())
                    if to_redirect and to_redirect ~= ngx_var_uri then
                        local redirect_status = tonumber(handle.redirect_status)
                        if redirect_status ~= 301 and redirect_status ~= 302 then
                            redirect_status = 301
                        end
                        -- ngx.HTTP_MOVED_PERMANENTLY (301)
                        -- ngx.HTTP_MOVED_TEMPORARILY (302)

                        if string_find(to_redirect, 'http') ~= 1 then
                            to_redirect = ngx_var_scheme .. "://" .. ngx_var_host .. to_redirect
                        end

                        if ngx_var.args ~= nil then
                            if string_find(to_redirect, '?') then -- 不存在?，直接缀上url args
                                if handle.trim_qs ~= true then
                                    to_redirect = to_redirect .. "&" .. ngx_var.args
                                end
                            else
                                if handle.trim_qs ~= true then
                                    to_redirect = to_redirect .. "?" .. ngx_var.args
                                end
                            end
                        end

                        if handle.log == true then
                            ngx.log(ngx.INFO, "[Redirect] ", ngx_var_uri, " to:", to_redirect)
                        end

                        ngx_redirect(to_redirect, redirect_status)
                    end
                end

                return
            end
        end
    end
end

return RedirectHandler