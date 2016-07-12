local type = type
local tonumber = tonumber
local ngx_md5 = ngx.md5
local string_gsub = string.gsub
local template = require("resty.template")
template.print = function(s)
  return s
end

local function compose(extractor_type, tmpl, variables)
    if not tmpl then return "" end
    if not variables or type(variables) ~= "table" then
        return tmpl
    end

    if not extractor_type or extractor_type == 1 then
        -- replace with ngx.re.gsub
        local result = string_gsub(tmpl, "%${([1-9]+)}", function(m)
            return variables[tonumber(m)]
        end)

        return result
    elseif extractor_type == 2 then
        return template.render(tmpl, variables, ngx_md5(tmpl), true)
    end
end

local _M = {}

---
-- @param extractor_type number, the extractor type 
-- @param url_tmpl string
--  extractor_type==1 then url template, contains variable placeholder ${number}, e.g. /user/${1}/friends/${2}
--  extractor_type==2 then url template, contains variable placeholder {{key.[subkey]}}, e.g. /user/{{host}}/friends/{{header.uid}}
-- @param variables array or map: variables used to compose url
--
function _M.build_url(extractor_type, url_tmpl, variables)
    return compose(extractor_type, url_tmpl, variables)
end

---
-- @param extractor_type number, the extractor type 
-- @param uri_tmpl string
--  extractor_type==1 then url template, contains variable placeholder ${number}, e.g. /user/${1}/friends/${2}
--  extractor_type==2 then url template, contains variable placeholder {{key.[subkey]}}, e.g. /user/{{host}}/friends/{{header.uid}}
-- @param variables array or map: variables used to compose url
--
function _M.build_uri(extractor_type, uri_tmpl, variables)
    return compose(extractor_type, uri_tmpl, variables)
end


function _M.build_upstream_host(extractor_type, upstream_host_tmpl, variables)
    return compose(extractor_type, upstream_host_tmpl, variables)
end

function _M.build_upstream_url(extractor_type, upstream_url_tmpl, variables)
    return compose(extractor_type, upstream_url_tmpl, variables)
end


return _M