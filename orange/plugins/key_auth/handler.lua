local pairs = pairs
local ipairs = ipairs
local type = type
local string_find = string.find

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base")


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


local KeyAuthHandler = BasePlugin:extend()
KeyAuthHandler.PRIORITY = 2000

function KeyAuthHandler:new(store)
    KeyAuthHandler.super.new(self, "key_auth-plugin")
    self.store = store
end

function KeyAuthHandler:access(conf)
    KeyAuthHandler.super.access(self)
    
    local key_auth_config = {
        enable = orange_db.get("key_auth.enable"),
        rules = orange_db.get_json("key_auth.rules")
    }
    if not key_auth_config or key_auth_config.enable ~= true then
        return
    end
    local rules = key_auth_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end

    local headers = ngx.req.get_headers()
    local content_type = headers['Content-Type']
    local body = get_body(content_type)
    local query = ngx.req.get_uri_args()
    
    local ngx_var = ngx.var
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
                pass = judge_util.filter_complicated_conditions(judge.expression, conditions)
            end

            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle.credentials then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[KeyAuth-Pass-Rule] ", rule.name, " uri:", ngx_var.uri)
                    end

                    local authorized = is_authorized(handle.credentials, headers, query, body)
                    if authorized then
                        return
                    else
                        return ngx.exit(tonumber(handle.code) or 401)
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[KeyAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var.uri)
                    end
                    return ngx.exit(tonumber(handle.code) or 401)
                end
            end
        end
    end
end

return KeyAuthHandler
