local pairs = pairs
local ipairs = ipairs
local ngx_re_sub = ngx.re.sub
local ngx_re_find = ngx.re.find
local string_sub = string.sub
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
local headers_util = require("orange.utils.headers")
local BasePlugin = require("orange.plugins.base_handler")
local ngx_set_uri_args = ngx.req.set_uri_args
local ngx_decode_args = ngx.decode_args


local function filter_rules(sid, plugin)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")

    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, "headers")
            -- handle阶段
            if pass then
                -- extract阶段
                headers_util:set_headers(rule)
            end
        end
    end

    return false
end

local HeaderHandler = BasePlugin:extend()
HeaderHandler.PRIORITY = 2000

function HeaderHandler:new(store)
    HeaderHandler.super.new(self, "headers-plugin")
    self.store = store
end

function HeaderHandler:rewrite(conf)
    HeaderHandler.super.rewrite(self)

    local enable = orange_db.get("headers.enable")
    local meta = orange_db.get_json("headers.meta")
    local selectors = orange_db.get_json("headers.selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    for i, sid in ipairs(ordered_selectors) do
        local selector = selectors[sid]
        ngx.log(ngx.INFO, "==[Headers][START SELECTOR:", sid, "][NAME:",selector.name,']')
        if selector and selector.enable == true then
            local selector_pass
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "headers")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Headers][PASS-SELECTOR:", sid, "]")
                end

                local stop = filter_rules(sid, "headers")
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[Headers][NOT-PASS-SELECTOR:", sid, "] ")
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

return HeaderHandler
