local socket = require("socket")
local _M = {}
local base = require "resty.core.base"
base.allows_subsystem("http")
local get_request = base.get_request

--- 将斜杠 / 转移后的 &#47;，转回正常斜杠符号
function _M.htmlDecode(s)
    return string.gsub(s,"&#47;","/");
end

function _M.hostToIp(hostname)
    ngx.log(ngx.ERR,"=================解析ip==================")
    local ip, resolved = socket.dns.toip(hostname)
    if resolved then
        ngx.log(ngx.ERR,"解析出的ip: ",ip)
        return ip
    end
    ngx.log(ngx.ERR,"=================解析错误,返回127.0.0.1==================")
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
