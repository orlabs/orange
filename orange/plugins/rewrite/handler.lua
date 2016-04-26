local pairs = pairs
local ipairs = ipairs
local string_len = string.len
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

    local rewrite_config 
    if self.store.store_type == "file" then
        rewrite_config = self.store:get("rewrite_config")
    elseif self.store.store_type == "mysql" then
        rewrite_config = {
            enable = orange_db.get("rewrite.enable"),
            rules = orange_db.get_json("rewrite.rules")
        }
    end
    
    if not rewrite_config or rewrite_config.enable ~= true then
        return
    end

    local ngx_var_uri = ngx.var.uri
    local ngx_set_uri = ngx.req.set_uri

    local rules = rewrite_config.rules
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
            local extractions = extractor and extractor.extractions
            local variables
            if extractions then
                variables = extractor_util.extract(extractions)
            end

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle and handle.uri_tmpl then
                    local to_rewrite = handle_util.build_uri(handle.uri_tmpl, variables, self:get_name())
                    if to_rewrite and to_rewrite ~= ngx_var_uri then
                        if handle.log == true then
                            ngx.log(ngx.ERR, "[Rewrite] ", ngx_var_uri, " to:", to_rewrite)
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