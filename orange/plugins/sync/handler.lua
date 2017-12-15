local ipairs = ipairs
local type = type
local encode_base64 = ngx.encode_base64
local string_format = string.format
local string_gsub = string.gsub

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")

local function get_encoded_credential(origin)
    local result = string_gsub(origin, "^ *[B|b]asic *", "")
    result = string_gsub(result, "( *)$", "")
    return result
end

local function is_authorized(authorization, credentials)
    if not authorization or not credentials then return false end

    if type(authorization) == "string" and authorization ~= "" then
        local encoded_credential = get_encoded_credential(authorization)

        for j, v in ipairs(credentials) do
            local allowd = encode_base64(string_format("%s:%s", v.username, v.password))
            if allowd == encoded_credential then -- authorization passed
                return true
            end
        end
    end

    return false
end

local function filter_rules(sid, plugin, ngx_var_uri, authorization)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, plugin)

            -- handle阶段
            local handle = rule.handle or {}
            if pass then
                if handle.credentials then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Pass-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end

                    local authorized = is_authorized(authorization, handle.credentials)
                    if authorized then
                        return true
                    else
                        ngx.exit(tonumber(handle.code) or 401)
                        return true
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    ngx.exit(tonumber(handle.code) or 401)

                    return true
                end
            end
        end
    end

    return false
end


local BasicAuthHandler = BasePlugin:extend()
BasicAuthHandler.PRIORITY = 2000

function BasicAuthHandler:new(store)
    BasicAuthHandler.super.new(self, "basic_auth-plugin")
    self.store = store
end

function BasicAuthHandler:access(conf)
    BasicAuthHandler.super.access(self)
    
    local enable = orange_db.get("basic_auth.enable")
    local meta = orange_db.get_json("basic_auth.meta")
    local selectors = orange_db.get_json("basic_auth.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end
    
    local ngx_var_uri = ngx.var.uri
    local headers = ngx.req.get_headers()
    local authorization = headers and (headers["Authorization"] or headers["authorization"])

    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[BasicAuth][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "basic_auth")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[BasicAuth][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "basic_auth", ngx_var_uri, authorization)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[BasicAuth][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return BasicAuthHandler
