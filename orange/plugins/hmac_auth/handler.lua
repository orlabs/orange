local ipairs            = ipairs
local tonumber          = tonumber
local tostring          = tostring
local type              = type
local string_lower      = string.lower
local table_insert      = table.insert
local table_concat      = table.concat
local math_abs          = math.abs
local ngx_time          = ngx.time
local ngx_log           = ngx.log
local ngx_exit          = ngx.exit
local ngx_INFO          = ngx.INFO
local ngx_parse_time    = ngx.parse_http_time
local ngx_re_match      = ngx.re.match
local ngx_encode_base64 = ngx.encode_base64
local orange_db         = require "orange.store.orange_db"
local judge_util        = require "orange.utils.judge"
local BasePlugin        = require "orange.plugins.base_handler"
local ngx_hmac_sha1     = ngx.hmac_sha1
--local openssl_hmac      = require "openssl.hmac"

local PLUGIN_NAME   = "hmac_auth"
local AUTHORIZATION = "authorization"
local X_DATE        = "x-date"

-- 字符串分隔
local function string_split(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table_insert(result, match)
    end
    return result
end

--HMAC算法
local hmac = {
    ["hmac-sha1"] = function(secret, data)
        return ngx_hmac_sha1(secret, data)
    end,
--    ["hmac-sha256"] = function(secret, data)
--        return openssl_hmac.new(secret, "sha256"):final(data)
--    end,
--    ["hmac-sha384"] = function(secret, data)
--        return openssl_hmac.new(secret, "sha384"):final(data)
--    end,
--    ["hmac-sha512"] = function(secret, data)
--        return openssl_hmac.new(secret, "sha512"):final(data)
--    end
}

-- 校验时间是否合法
local function validate_xdate(headers, credentials)
    local xdate = headers[X_DATE] or nil
    if not xdate then
        return false, "A valid x-date header is required for HMAC Authentication"
    end

    local xtime = ngx_parse_time(xdate)
    if not xtime then
        return false, "X-DATE header must is Time(GMT)"
    end

    local skew = math_abs(ngx_time() - xtime)
    if skew > credentials.timeout then
        return false, "X-DATE header expired"
    end

    return true, nil
end

-- 获取Authorization中参数
local function retrieve_params(headers)
    local authorization = headers[AUTHORIZATION] or nil
    if not authorization then
        return nil, "A valid Authorization header is required for HMAC Authentication"
    end

    local params = ngx_re_match(authorization, "\\s*[Hh]mac\\s*algorithm=\"(.+)\",\\s*headers=\"(.+)\",\\s*signature=\"(.+)\"")
    if not params or #params ~= 3 then
        return nil, "Authorization header format error or not exists"
    end

    local response = {}
    response.algorithm = string_lower(params[1])
    response.headers = string_split(params[2], ",")
    response.signature = tostring(params[3])
    return response, nil
end

-- 计算签名
local function create_sign(headers, params, credentials)
    local params_headers = params.headers
    local params_count = #params_headers

    local hmac_headers = {}
    for i = 1, params_count do
        local header_key = tostring(params_headers[i])
        local header_val = tostring(headers[header_key])
        table_insert(hmac_headers, header_key .. ":" .. header_val)
    end

    local hmac_string = table_concat(hmac_headers, "\n")
    return ngx_encode_base64(hmac[credentials.algorithm](credentials.secret, hmac_string))
end

-- 验证授权
local function is_authorized(credentials, headers)
    local succ = validate_xdate(headers, credentials)
    if not succ then
        return false
    end

    local params = retrieve_params(headers)
    if not params then
        return false
    end

    if params.algorithm ~= credentials.algorithm then
        return false
    end

    local signature = create_sign(headers, params, credentials)
    if signature == params.signature then
        return true
    else
        return false
    end
end

local function filter_rules(selector_id, ngx_var_uri, headers)
    local rules = orange_db.get_json(PLUGIN_NAME .. ".selector." .. selector_id .. ".rules")
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end

    for _, rule in ipairs(rules) do
        local enable = rule.enable
        if enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, PLUGIN_NAME)
            -- handle阶段
            if pass then
                local handle = rule.handle
                if handle.credentials then
                    if handle.log == true then
                        ngx_log(ngx_INFO, "[HmacAuth-Pass-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    local authorized = is_authorized(handle.credentials, headers)
                    if authorized then
                        return true
                    else
                        ngx_exit(tonumber(handle.code) or 401)
                        return true
                    end
                else
                    if handle.log == true then
                        ngx_log(ngx_INFO, "[HmacAuth-Forbidden-Rule] ", rule.name, " uri:", ngx_var_uri)
                    end
                    ngx_exit(tonumber(handle.code) or 401)
                    return true
                end
            end
        end
    end
end

local HmacAuthHandler = BasePlugin:extend()
HmacAuthHandler.PRIORITY = 2000

function HmacAuthHandler:new(store)
    HmacAuthHandler.super.new(self, "hmac_auth-plugin")
    self.store = store
end

function HmacAuthHandler:access(conf)
    HmacAuthHandler.super.access(self)
    -- 获取插件启用状态
    local enable = orange_db.get(PLUGIN_NAME .. ".enable")
    if not enable then
        return
    end
    -- 获取插件选择器信息
    local selectors = orange_db.get_json(PLUGIN_NAME .. ".selectors")
    if not selectors then
        return
    end
    -- 获取插件元信息
    local meta = orange_db.get_json(PLUGIN_NAME .. ".meta")
    -- 获取信息中选择器IDs
    local ordered_selectors = meta and meta.selectors
    if not ordered_selectors then
        return
    end

    local ngx_var_uri = ngx.var.uri
    local headers = ngx.req.get_headers()

    for _, selector_id in ipairs(ordered_selectors) do
        -- 选中规则并检查当前规则是否为开启状态
        local selector = selectors[selector_id]
        if selector and selector.enable == true then
            local selector_pass
            -- 全流量选择器
            if selector.type == 0 then
                selector_pass = true
            else
                -- selector judge
                selector_pass = judge_util.judge_selector(selector, PLUGIN_NAME)
            end

            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx_log(ngx_INFO, "[HmacAuth][PASS-SELECTOR:", selector_id, "] ", ngx_var_uri)
                end

                local stop = filter_rules(selector_id, ngx_var_uri, headers)
                if stop then -- 不再执行此插件其他逻辑
                    return
                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx_log(ngx_INFO, "[HmacAuth][NOT-PASS-SELECTOR:", selector_id, "] ", ngx_var_uri)
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

return HmacAuthHandler
