local socket = require("socket")
local _M = {}
local base = require "resty.core.base"
base.allows_subsystem("http")
local get_request = base.get_request
local string_lower = string.lower
local string_find = string.find
local cjson = require "cjson"
waf_html=[[
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>网站防火墙</title>
<style>
p {
	line-height:20px;
}
ul{ list-style-type:none;}
li{ list-style-type:none;}
</style>
</head>

<body style=" padding:0; margin:0; font:14px/1.5 Microsoft Yahei, 宋体,sans-serif; color:#555;">

 <div style="margin: 0 auto; width:1000px; padding-top:70px; overflow:hidden;">


  <div style="width:600px; float:left;">
    <div style=" height:40px; line-height:40px; color:#fff; font-size:16px; overflow:hidden; background:#6bb3f6; padding-left:20px;">网站防火墙 </div>
    <div style="border:1px dashed #cdcece; border-top:none; font-size:14px; background:#fff; color:#555; line-height:24px; height:220px; padding:20px 20px 0 20px; overflow-y:auto;background:#f3f7f9;">
      <p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;"><span style=" font-weight:600; color:#fc4f03;">您的请求带有不合法参数，已被网站管理员设置拦截！</span></p>
<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">可能原因：您提交的内容包含危险的攻击请求</p>
<p style=" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:1; text-indent:0px;">如何解决：</p>
<ul style="margin-top: 0px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; -qt-list-indent: 1;"><li style=" margin-top:12px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">1）检查提交内容；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">2）如网站托管，请联系空间提供商；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">3）普通网站访客，请联系网站管理员；</li></ul>
    </div>
  </div>
</div>
</body></html>
]]

--- 将斜杠 / 转移后的 &#47;，转回正常斜杠符号
function _M.htmlDecode(s)
    return string.gsub(s,"&#47;","/");
end

-- get request params str by one of these methods(get/delete/put/post)
function _M.getReqParamsStr(ngx)
    local args = {}
    -- 处理uri
    for part in string.gmatch(ngx.var.uri, "([^/]+)") do
        if part and part ~= '' then
            table.insert(args, part)
        end
    end
    -- 处理url params
    local uri_args = ngx.req.get_uri_args()
    if uri_args ~= nil and next(uri_args) ~= nil then
        for k, v in pairs(uri_args) do
            if v and v ~= '' then
                table.insert(args, v)
            end
        end
    end
    -- 处理req body
    if ngx.req.get_method() == "PUT" or ngx.req.get_method() == "POST" then
        local headers = ngx.req.get_headers()
        local header = headers['Content-Type']
        if header then
            local body_args
            local is_multipart = string_find(header, "multipart")
            if is_multipart and is_multipart > 0 then
                -- do not check file
            elseif header == "application/x-www-form-urlencoded" then
                ngx.req.read_body()
                body_args = ngx.req.get_post_args()
            elseif header == "application/json" then
                ngx.req.read_body()
                local data = ngx.req.get_body_data()
                body_args = cjson.decode(data)
            end
            if body_args ~= nil and next(body_args) ~= nil then
                for k, v in pairs(body_args) do
                    if v and v ~= '' then
                        table.insert(args, v)
                    end
                end
            end
        end
    end
    if args and next(args) ~= nil then
        args = table.unique(args)
    end
    return args
end

-- waf return html
function _M.waf_html()
    ngx.header.content_type = "text/html"
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say(waf_html)
    ngx.exit(ngx.status)
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
