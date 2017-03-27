local ipairs = ipairs
local type = type
local encode_base64 = ngx.encode_base64
local string_format = string.format
local string_gsub = string.gsub
local tabel_insert = table.insert

local utils = require("orange.utils.utils")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local handle_util = require("orange.utils.handle")
local BasePlugin = require("orange.plugins.base_handler")
local extractor_util = require("orange.utils.extractor")

local function is_authorized(signature_name, secretKey,extractor)

    if not signature_name or not secretKey then
        return false,'sig or secret key config error'
    end

    if extractor == nil or next(extractor) == nil  then
        return false,'extractor empty'
    end

    local check_sig = function(extractions,secretKey)
        local param = {}
        local req_val = {}

        for i, extraction in ipairs(extractions) do
            local name = extraction.name
            tabel_insert(param,name)
            local temp= extractor_util.extract_variable(extraction)
            if  temp then
                req_val[name]  = temp
            else
                return false ,name.." is empty"
            end
        end

        local signature = req_val[signature_name]
        req_val[signature_name]=nil

        local md5 = require("resty.md5")
        local md5 = md5:new()
        if not md5 then
            ngx.log(ngx.ERR,'server error exec md5:new faild')
            return false
        end

        for _, v in ipairs(param) do
            if req_val[v] then
                local ok = md5:update(req_val[v])
                if not ok then
                    ngx.log(ngx.ERR,'server error exec md5:update faild')
                    return false
                end
            end
        end

        local ok = md5:update(secretKey)
        if not ok then
            ngx.log(ngx.ERR,'server error exec md5:update faild')
            return false
        end

        local str = require "resty.string"
        local calc_sig = str.to_hex(md5:final())

        return calc_sig == signature
    end

    return check_sig(extractor.extractions,secretKey)

end

local function filter_rules(sid, plugin, ngx_var_uri)
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
                        ngx.log(ngx.INFO, "[SignatureAuth-Pass-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    local credentials = handle.credentials
                    local authorized = is_authorized(credentials.signame,credentials.secretkey,rule.extractor)
                    if authorized then
                        return true
                    else
                        ngx.exit(tonumber(handle.code) or 401)
                        return true
                    end
                else
                    if handle.log == true then
                        ngx.log(ngx.INFO, "[SignatureAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    ngx.exit(tonumber(handle.code) or 401)
                    return true
                end
            end
        end
    end

    return false
end


local SignatureAuthHandler = BasePlugin:extend()
SignatureAuthHandler.PRIORITY = 2000

function SignatureAuthHandler:new(store)
    SignatureAuthHandler.super.new(self, "signature_auth-plugin")
    self.store = store
end

function SignatureAuthHandler:access(conf)
    SignatureAuthHandler.super.access(self)

    local enable = orange_db.get("signature_auth.enable")
    local meta = orange_db.get_json("signature_auth.meta")
    local selectors = orange_db.get_json("signature_auth.selectors")
    local ordered_selectors = meta and meta.selectors

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    local ngx_var_uri = ngx.var.uri

    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[SignatureAuth][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local selector_pass
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "signature_auth")-- selector judge
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[SignatureAuth][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end

                local stop = filter_rules(sid, "signature_auth", ngx_var_uri)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[SignatureAuth][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
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

return SignatureAuthHandler
