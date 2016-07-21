local pairs = pairs
local ipairs = ipairs
local type = type

local table_insert = table.insert
local encode_base64 = ngx.encode_base64
local string_lower = string.lower
local string_format = string.format
local string_sub = string.sub
local string_gsub = string.gsub
local string_len = string.len

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base")

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


local BasicAuthHandler = BasePlugin:extend()
BasicAuthHandler.PRIORITY = 2000

function BasicAuthHandler:new(store)
    BasicAuthHandler.super.new(self, "basic_auth-plugin")
    self.store = store
end

function BasicAuthHandler:access(conf)
    BasicAuthHandler.super.access(self)
    
    local basic_auth_config = {
        enable = orange_db.get("basic_auth.enable"),
        rules = orange_db.get_json("basic_auth.rules")
    }
    if not basic_auth_config or basic_auth_config.enable ~= true then
        return
    end
    local rules = basic_auth_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end

    local headers = ngx.req.get_headers()
    local authorization = headers and (headers["Authorization"] or headers["authorization"])
    
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
            local handle = rule.handle
            if pass then
                if handle.credentials then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Pass-Rule] ", rule.name, " uri:", ngx_var.uri)
                    end

                    local authorized = is_authorized(authorization, handle.credentials)
                    if authorized then
                        return
                    else
                        return ngx.exit(tonumber(handle.code) or 401)
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var.uri)
                    end
                    return ngx.exit(tonumber(handle.code) or 401)
                end
            end
        end
    end
end

return BasicAuthHandler