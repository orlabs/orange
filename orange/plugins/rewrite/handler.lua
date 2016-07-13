local pairs = pairs
local ipairs = ipairs
local ngx_re_sub = ngx.re.sub
local ngx_re_find = ngx.re.find
local string_len = string.len
local string_sub = string.sub
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base")


local RewriteHandler = BasePlugin:extend()
RewriteHandler.PRIORITY = 2000

function RewriteHandler:new(store)
    RewriteHandler.super.new(self, "rewrite-plugin")
    self.store = store
end

function RewriteHandler:rewrite(conf)
    RewriteHandler.super.rewrite(self)

    local rewrite_config = {
        enable = orange_db.get("rewrite.enable"),
        rules = orange_db.get_json("rewrite.rules")
    }
    
    if not rewrite_config or rewrite_config.enable ~= true then
        return
    end

    local ngx_var_uri = ngx.var.uri
    local ngx_set_uri = ngx.req.set_uri
    local ngx_set_uri_args = ngx.req.set_uri_args
    local ngx_decode_args = ngx.decode_args

    local rules = rewrite_config.rules
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
                if handle and handle.uri_tmpl then
                    local to_rewrite = handle_util.build_uri(extractor_type, handle.uri_tmpl, variables, self:get_name())
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

                return
            end
        end
    end
end

return RewriteHandler