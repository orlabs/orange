local type = type
local tonumber = tonumber
local string_gsub = string.gsub

local function compose(tmpl, variables)
    if not tmpl then return "" end
    if not variables or type(variables) ~= "table" or #variables < 1 then
        return tmpl
    end

    -- replace with ngx.re.gsub
    local result = string_gsub(tmpl, "%${([1-9]+)}", function(m)
        return variables[tonumber(m)]
    end)

    return result
end


local _M = {}

---
-- @param url_tmpl string: url template, contains variable placeholder ${number},
--                 e.g. /user/${1}/friends/${2}
-- @param variables array: variables used to compose url
--
function _M.build_url(url_tmpl, variables)
    return compose(url_tmpl, variables)
end

---
-- @param uri_tmpl string: uri template, contains variable placeholder ${number},
--                 e.g. /user/${1}/friends/${2}, the number is `lua array index`
-- @param variables array: variables used to compose url
--
function _M.build_uri(uri_tmpl, variables)
    return compose(uri_tmpl, variables)
end


function _M.build_upstream_host(upstream_host_tmpl, variables)
    return compose(upstream_host_tmpl, variables)
end

function _M.build_upstream_url(upstream_url_tmpl, variables)
    return compose(upstream_url_tmpl, variables)
end


return _M