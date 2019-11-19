local str_sub = string.sub
local str_find = string.find

local _M = {}

function _M.plugin_headers()
    ngx.say("uri: ", ngx.var.uri)
    local headers = ngx.req.get_headers()
    for k, v in pairs(headers) do
        ngx.say(k, ": ", v)
    end
end

function _M.plugin_redirect()
    ngx.say("uri: ", ngx.var.uri)
    local headers = ngx.req.get_headers()
    for k, v in pairs(headers) do
        ngx.say(k, ": ", v)
    end
end

function _M.go()
    local action = str_sub(ngx.var.uri, 2)
    local find = str_find(action, "/", 1, true)
    if find then
        action = str_sub(action, 1, find - 1)
    end

    if not action or not _M[action] then
        return ngx.exit(404)
    end

    return _M[action]()
end

return _M
