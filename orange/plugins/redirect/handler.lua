local pairs = pairs
local ipairs = ipairs
local string_len = string.len
local string_find = string.find
local ngx_re_gsub = ngx.re.gsub
local ngx_redirect = ngx.redirect
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
    local redirect_config = self.store:get_redirect_config()
    if redirect_config.enable ~= true then
        return
    end

    local ngx_var = ngx.var
    local ngx_var_uri = ngx_var.uri
    local ngx_var_host = ngx_var.http_host
    local ngx_var_scheme = ngx_var.scheme

    local redirect_rules = redirect_config.redirect_rules
    for i, rule in ipairs(redirect_rules) do
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
            local extractions = extractor and extractor.extractions
            local variables
            if extractions then
                variables = extractor_util.extract(extractions)
            end

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle and handle.url_tmpl then
                    local new_url = handle_util.build_url(handle.url_tmpl, variables, self:get_name())
                    if new_url ~= ngx_var_uri then
                        local redirect_status = tonumber(handle.redirect_status)
                        -- ngx.HTTP_MOVED_PERMANENTLY (301)
                        -- ngx.HTTP_MOVED_TEMPORARILY (302)

                        if string_find(new_url, 'http') ~= 1 then
                            new_url = ngx_var_scheme .. "://" .. ngx_var_host .. new_url
                        end

                        if ngx_var.args ~= nil then
                            new_url = new_url .. "?" .. ngx_var.args
                        end

                        ngx_redirect(new_url, redirect_status or ngx.HTTP_MOVED_TEMPORARILY)

                        if handle.log == true then
                            ngx.log(ngx.ERR, "[Redirect] ", ngx_var_uri, " to:", new_url)
                        end
                    end
                end

                return
            end
        end
    end
end

return RedirectHandler