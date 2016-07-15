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
local cjson = require("cjson")

local function get_encoded_credential(origin)
    local result = string_gsub(origin, "^ *[B|b]asic *", "")
    result = string_gsub(result, "( *)$", "")
    return result
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

    local ngx_var = ngx.var

    local rules = basic_auth_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end


    local headers = ngx.req.get_headers()
    local authorization = headers and (headers["Authorization"] or headers["authorization"])
    
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


            -- handle阶段
            if pass then
                if handle.credentials then
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Pass-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end


                    if type(authorization) == "string" and authorization ~= "" then
                        local encoded_credential = get_encoded_credential(authorization)

                        for i, v in ipairs(credentials) do
                            local allowd = encode_base64(string_format("%s:%s", v.username, v.password))
                            if allowd == encoded_credential then
                                next()
                                return
                            end
                        end
                    end

                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[BasicAuth-Forbidden-Rule] ", rule.name, " uri:", ngx.var.uri)
                    end
                    ngx.exit(tonumber(handle.code) or 401)
                    return
                end
            end
        end
    end
end

return BasicAuthHandler