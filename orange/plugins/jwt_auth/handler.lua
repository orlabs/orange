local ipairs = ipairs
local type = type
local string_find = string.find

local jwt = require("resty.jwt")
local utils = require("orange.utils.utils")
local cjson = require("cjson")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

local function jwt_auth(credentials, jwttoken)
    local secret = credentials.secret
    local jwtobj = jwt:verify(secret, jwttoken)
    if jwtobj["verified"] then
        for i, payload in ipairs(credentials.payload) do  
            if payload.type == 1 then
                ngx.req.set_header(payload.target_key, jwtobj.payload[payload.key])
            end
        end 

        return true
    end
    return false
end

local function is_credential_in_header(credentials, headers)
    local jwttoken = headers["Authorization"]
    if not jwttoken then return false end
    return jwt_auth(credentials, string.split(jwttoken, " ")[2])
end


local function is_credential_in_query(credentials, query)
    if not query or not "token" then return false end
    local jwttoken = query["token"]
    return jwt_auth(credentials, jwttoken)
end



local function is_authorized(credentials, headers, query)
    if not credentials then return false end
    local authorized = false

    if is_credential_in_header(credentials,headers) then
                authorized = true
    elseif is_credential_in_query(credentials,query) then
                authorized = true
    end

    return authorized
end

local function filter_rules(sid, plugin, ngx_var_uri, headers, query)
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
                        ngx.log(ngx.INFO, "[JwtAuth-Pass-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                     
                    local authorized = is_authorized(handle.credentials, headers, query)
                    if authorized then
                        return true
                    else
                        ngx.exit(tonumber(handle.code) or 401)
                        return true
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[JwtAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    ngx.exit(tonumber(handle.code) or 401)

                    return true
                end
            end
        end
    end

    return false
end


local JwtAuthHandler = BasePlugin:extend()
JwtAuthHandler.PRIORITY = 2000

function JwtAuthHandler:new(store)
    JwtAuthHandler.super.new(self, "jwt_auth-plugin")
    self.store = store
end

function JwtAuthHandler:access(conf)
    JwtAuthHandler.super.access(self)
    
    local enable = orange_db.get("jwt_auth.enable")
    local meta = orange_db.get_json("jwt_auth.meta")
    local selectors = orange_db.get_json("jwt_auth.selectors")
    local ordered_selectors = meta and meta.selectors
    
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local headers = ngx.req.get_headers()
    local content_type = headers['Content-Type']
    local query = ngx.req.get_uri_args()
    local ngx_var_uri = ngx.var.uri

    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[JwtAuth][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "jwt_auth")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[JwtAuth][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "jwt_auth", ngx_var_uri, headers, query)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[JwtAuth][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return JwtAuthHandler
