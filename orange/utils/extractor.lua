local type = type
local ipairs = ipairs
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


local _M = {}

function _M.extract(extractions)
    if not extractions or type(extractions) ~= "table" or #extractions < 1 then
        return {}
    end

    local result = {}
    for i, extraction in ipairs(extractions) do
        local variable = extract_variable(extraction)
        table_insert(result, variable)
    end

    return result
end


return _M
