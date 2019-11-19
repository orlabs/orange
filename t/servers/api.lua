local http = require("resty.http")
local json = require("cjson.safe")
local str_format = string.format
local type = type
local pairs = pairs

local _M = {}

local methods = {
    [ngx.HTTP_GET] = "GET",
    [ngx.HTTP_HEAD] = "HEAD",
    [ngx.HTTP_PUT] = "PUT",
    [ngx.HTTP_POST] = "POST",
    [ngx.HTTP_DELETE] = "DELETE",
    [ngx.HTTP_OPTIONS] = "OPTIONS",
    [ngx.HTTP_PATCH] = "PATCH",
}

local DEFAULT_SERVER_PORT = '1980'

function _M.http_build_query(body)
    local response
    if type(body) == "table" then
        local number = 0
        if type(body) == 'table' then
            for key, value in pairs(body) do
                if not value then
                    value = value or ''
                end
                if number == 0 then
                    response = str_format('%s=%s', key, value)
                else
                    response = str_format('%s&%s=%s', response, key, value)
                end
                number = number + 1
            end
        end
    else
        response = body
    end
    return response
end

function _M.selector(plugin_name)
    local selector_id
    local uri = str_format("%s://%s:%s/%s/selectors",
            ngx.var.scheme,
            ngx.var.server_addr,
            DEFAULT_SERVER_PORT or ngx.var.server_port,
            plugin_name
    )

    local httpc = http.new()
    local res, err = httpc:request_uri(uri,
            {
                method = "GET",
                keepalive = false,
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                },
            }
    )

    if res and res.status == 200 then
        local contents = json.decode(res.body)
        if contents.success and contents.data.meta.selectors then
            selector_id = contents.data.meta.selectors[1]
        end
    end

    return selector_id
end

function _M.go(uri, method, body)
    if type(body) == "table" then
        body = _M.http_build_query(body)
    end

    if type(method) == "number" then
        method = methods[method]
    end

    local httpc = http.new()
    uri = str_format("%s://%s:%s%s",
            ngx.var.scheme,
            ngx.var.server_addr,
            DEFAULT_SERVER_PORT or ngx.var.server_port,
            uri
    )

    local res, err = httpc:request_uri(uri,
            {
                method = method,
                body = body,
                keepalive = false,
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                },
            }
    )

    if not res then
        ngx.log(ngx.ERR, "failed http: ", err)
        return 404, "Not Found", nil
    end

    if res.status >= 300 then
        return res.status, err, res.body
    end

    if json.decode(res.body).success then
        return res.status, "OK", res.body
    else
        return res.status, "FAIL", res.body
    end

end

return _M
