local socket = require("socket")
local _M = {}
local base = require "resty.core.base"
base.allows_subsystem("http")
local get_request = base.get_request
local string_lower = string.lower
local string_find = string.find
local cjson = require "cjson"


--- 将斜杠 / 转移后的 &#47;，转回正常斜杠符号
function _M.htmlDecode(s)
    return string.gsub(s,"&#47;","/");
end

-- get request params str by one of these methods(get/delete/put/post)
function _M.getReqParamsStr(ngx)
    local args
    if ngx.req.get_method() == "GET" or ngx.req.get_method() == "DELETE" then
        args = ngx.req.get_uri_args()
    elseif ngx.req.get_method() == "PUT" or ngx.req.get_method() == "POST" then
        -- no check file
        local headers = ngx.req.get_headers()
        local header = headers['Content-Type']
        if header then
            local is_multipart = string_find(header, "multipart")
            if is_multipart and is_multipart > 0 then
                return ""
            end
        end
        ngx.req.read_body()
        args = ngx.req.get_post_args()
    end
    if next(args) ~= nil then
        -- 后续逻辑相同,使用args处理参数
        local querystring = ""
        -- 拼接参数
        for k,v in pairs(args) do
            if not querystring then
                querystring = v
            else
                querystring = querystring .. " " .. v
            end
        end
        ngx.log(ngx.ERR,"getReqParamsStr : ",querystring)
        -- 有参数
        return querystring
    else
        -- 无参数
        return ""
    end
end

function _M.dnsToIp(hostname)
    local ip, resolved = socket.dns.toip(hostname)
    if resolved then
        ngx.log(ngx.INFO,"dnsToIp - resolve ip : ",ip)
        return ip
    end
    return "127.0.0.1"
end

--- html转移后的字符转回正常符号
function _M.htmlEncode(s)
    local HTML_ENTITIES = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;",
        ["/"] = "&#47;"
    }
    return string.gsub(s, "[\">/<'&]", HTML_ENTITIES)
end

function _M.urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

function _M.urlDecode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function _M.toStringEx(value)
    if type(value)=='table' then
        return _M.tableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end

function _M.tableToStr(t)
    if t == nil then return "" end
    local retStr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
            signal = ""
        end

        if key == i then
            retStr = retStr..signal.._M.toStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retStr = retStr..signal..'['.._M.toStringEx(key).."]=".._M.toStringEx(value)
            else
                if type(key)=='userdata' then
                    retStr = retStr..signal.."*s".._M.tableToStr(getmetatable(key)).."*e".."=".._M.toStringEx(value)
                else
                    retStr = retStr..signal..key.."=".._M.toStringEx(value)
                end
            end
        end

        i = i+1
    end

    retStr = retStr.."}"
    return retStr
end

function _M.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function _M.log(level, ...)
    local r = get_request()
    if not r then
        return ngx.log(level, '[',os.date("%Y-%m-%d %H:%M:%S") ,'] ~ gateway_orange_service ~ ', '-',' ~ ', '-', ' ~ ', ngx.var.remote_addr, ' ~ ', ...)
    end
    local headers = ngx.req.get_headers()
    ngx.log(level, '[',os.date("%Y-%m-%d %H:%M:%S") ,'] ~ gateway_orange_service ~ ', headers["trace-id"], ' ~ ', '-', ' ~ ', ngx.var.remote_addr, ' ~ ', ...)
end

function _M.tableUniq(table1)
    local table2={}
    for key,val in pairs(table1) do
        table2[val]=true
    end
    local table3={}
    for key,val in pairs(table2) do
        table.insert(table3,key)--将key插入到新的table，构成最终的结果
    end
    return table3
end

return _M
