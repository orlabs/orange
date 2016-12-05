local ipairs = ipairs
local type = type
local string_find = string.find

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")


local function is_credential_in_header(headers, key, target_value)
    if not headers or not key or not target_value then return false end
    if type(headers) ~= "table" or key == "" then return false end

    if headers[key] == target_value then return true end
    return false
end

local function is_credential_in_query(query, key, target_value)
    if not query or not key or not target_value then return false end
    if type(query) ~= "table" or key == "" then return false end

    if query[key] == target_value then return true end
    return false
end

local function is_credential_in_body(body, key, target_value)
    if not body or not key or not target_value then return false end
    if type(body) ~= "table" or key == "" then return false end

    if body[key] == target_value then return true end
    return false
end

local function is_authorized(credentials, headers, query, body)
    if not credentials then return false end

    local authorized = false
    for j, v in ipairs(credentials) do
        local key = v.key
        local target_value = v.target_value
        local credential_type = tonumber(v.type)

        if credential_type == 1 then
            if is_credential_in_header(headers, key, target_value) then
                authorized = true
                break
            end
        elseif credential_type == 2 then
            if is_credential_in_query(query, key, target_value) then
                authorized = true
                break
            end
        elseif credential_type == 3 then
            if is_credential_in_body(body, key, target_value) then
                authorized = true
                break
            end
        end
    end

    return authorized
end

local function get_body(content_type)
    if content_type and type(content_type) == "string" then
        local is_multipart = string_find(content_type, "multipart")
        if is_multipart and is_multipart > 0 then
            return nil
        end
    end

    local body
    ngx.req.read_body()
    local post_args = ngx.req.get_post_args()
    if post_args and type(post_args) == "table" then
        body = {}
        for k,v in pairs(post_args) do
            body[k] = v
        end
    end

    return body
end

local function filter_rules(sid, plugin, ngx_var_uri, headers, body, query)
    local rules = orange_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for i, rule in ipairs(rules) do
        local enable = rule.enable
        if enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, plugin)

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle.credentials then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[KeyAuth-Pass-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end

                    local authorized = is_authorized(handle.credentials, headers, query, body)
                    if authorized then
                        return true
                    else
                        ngx.exit(tonumber(handle.code) or 401)
                        return true
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[KeyAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    ngx.exit(tonumber(handle.code) or 401)

                    return true
                end
            end
        end
    end

    return false
end


local KeyAuthHandler = BasePlugin:extend()
KeyAuthHandler.PRIORITY = 2000

function KeyAuthHandler:new(store)
    KeyAuthHandler.super.new(self, "key_auth-plugin")
    self.store = store
end

function KeyAuthHandler:access(conf)
    KeyAuthHandler.super.access(self)
    
    local enable = orange_db.get("key_auth.enable")
    local meta = orange_db.get_json("key_auth.meta")
    local selectors = orange_db.get_json("key_auth.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local headers = ngx.req.get_headers()
    local content_type = headers['Content-Type']
    local body = get_body(content_type)
    local query = ngx.req.get_uri_args()
    local ngx_var_uri = ngx.var.uri

    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[KeyAuth][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "key_auth")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[KeyAuth][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "key_auth", ngx_var_uri, headers, body, query)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[KeyAuth][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return KeyAuthHandler
