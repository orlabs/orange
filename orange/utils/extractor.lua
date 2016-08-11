local type = type
local ipairs = ipairs
local pairs = pairs
local string_find = string.find
local string_lower = string.lower
local table_insert = table.insert
local ngx_re_find = ngx.re.find
local ngx_re_match = ngx.re.match

local function extract_variable(extraction)
    if not extraction or not extraction.type then
        return ""
    end

    local etype = extraction.type
    local result = ""

    if etype == "URI" then -- 为简化逻辑，URI模式每次只允许提取一个变量
        local uri = ngx.var.uri
        local m, err = ngx_re_match(uri, extraction.name)
        if not err and m and m[1] then
            result = m[1] -- 提取第一个匹配的子模式
        end
    elseif etype == "Query" then
        local query = ngx.req.get_uri_args()
        result = query[extraction.name]
    elseif etype == "Header" then
        local headers = ngx.req.get_headers()
        result = headers[extraction.name]
    elseif etype == "PostParams" then
        local headers = ngx.req.get_headers()
        local header = headers['Content-Type']
        if header then
            local is_multipart = string_find(header, "multipart")
            if is_multipart and is_multipart > 0 then
                return false
            end
        end
        ngx.req.read_body()
        local post_params, err = ngx.req.get_post_args()
        if not post_params or err then
            ngx.log(ngx.ERR, "[Extract Variable]failed to get post args: ", err)
            return false
        end
        result = post_params[extraction.name]
    elseif etype == "Host" then
        result = ngx.var.host
    elseif etype == "IP" then
        result =  ngx.var.remote_addr
    elseif etype == "Method" then
        local method = ngx.req.get_method()
        result = string_lower(method)
    end

    return result
end


local function extract_variable_for_template(extractions)
    if not extractions then
        return {}
    end

    local result = {}

    local ngx_var = ngx.var
    for i, extraction in ipairs(extractions) do
        local etype = extraction.type
        if etype == "URI" then -- URI模式通过正则可以提取出N个值
            result["uri"] = {} -- fixbug: nil `uri` variable for tempalte parse
            local uri = ngx_var.uri
            local m, err = ngx_re_match(uri, extraction.name)
            if not err and m and m[1] then
                if not result["uri"] then result["uri"] = {} end
                for j, v in ipairs(m) do
                    if j >= 1 then
                        result["uri"]["v" .. j] = v
                    end
                end
            end
        elseif etype == "Query" then
            local query = ngx.req.get_uri_args()
            if not result["query"] then result["query"] = {} end
            result["query"][extraction.name] = query[extraction.name] or extraction.default
        elseif etype == "Header" then
            local headers = ngx.req.get_headers()
            if not result["header"] then result["header"] = {} end
            result["header"][extraction.name]  = headers[extraction.name] or extraction.default
        elseif etype == "PostParams" then
            local headers = ngx.req.get_headers()
            local header = headers['Content-Type']
            local ok = true
            if header then
                local is_multipart = string_find(header, "multipart")
                if is_multipart and is_multipart > 0 then
                    ok = false
                end
            end
            ngx.req.read_body()
            local post_params, err = ngx.req.get_post_args()
            if not post_params or err then
                ngx.log(ngx.ERR, "[Extract Variable]failed to get post args: ", err)
                ok = false
            end

            if ok then
                if not result["body"] then result["body"] = {} end
                result["body"][extraction.name] = post_params[extraction.name] or extraction.default
            end
        elseif etype == "Host" then
            result["host"] = ngx_var.host or extraction.default
        elseif etype == "IP" then
            result["ip"] =  ngx_var.remote_addr or extraction.default
        elseif etype == "Method" then
            local method = ngx.req.get_method()
            result["method"] = string_lower(method)
        end
    end

    return result
end


local _M = {}

function _M.extract(extractor_type, extractions)
    if not extractions or type(extractions) ~= "table" or #extractions < 1 then
        return {}
    end

    if not extractor_type then
        extractor_type = 1
    end

    local result = {}
    if extractor_type == 1 then -- simple variables extractor
        for i, extraction in ipairs(extractions) do
            local variable = extract_variable(extraction) or extraction.default or ""
            table_insert(result, variable)
        end
    elseif extractor_type == 2 then -- tempalte variables extractor
        result = extract_variable_for_template(extractions)
    end

    -- for i, v in pairs(result) do
    --     if type(v) == "table" then
    --          for j, m in pairs(v) do
    --             ngx.log(ngx.ERR, i, ":", j, ":", m)
    --          end
    --     else
    --         ngx.log(ngx.ERR, i, ":", v)
    --     end
    -- end

    return result
end

return _M
