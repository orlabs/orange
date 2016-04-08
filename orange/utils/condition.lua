local sfind = string.find
local slower = string.lower

local _M = {}

function _M.judge(condition)
    local test_type = condition.type
    if not test_type or not condition then
        return false
    end

    local pass = false
    if test_type == "URI" then
        pass = _M.test_uri(condition)
    elseif test_type == "Query" then
        pass = _M.test_query(condition)
    elseif test_type == "Header" then
        pass = _M.test_header(condition)
    elseif test_type == "IP" then
        pass = _M.test_ip(condition)
    elseif test_type == "UserAgent" then
        pass = _M.test_ua(condition)
    elseif test_type == "Method" then
        pass = _M.test_method(condition)
    elseif test_type == "PostParams" then
        pass = _M.test_post_params(condition)
    elseif test_type == "Referer" then
        pass = _M.test_referer(condition)
    elseif test_type == "Host" then
        pass = _M.test_host(condition)
    end

    return pass
end

-- query string judge
function _M.test_query(condition)
    local query = ngx.req.get_uri_args()
    return _M.test_var(condition, query[condition.name])
end

function _M.test_uri(condition)
    local uri = ngx.var.uri
    return _M.test_var(condition, uri)
end

function _M.test_header(condition)
    local headers = ngx.req.get_headers()
    return _M.test_var(condition, headers[condition.name])
end

function _M.test_ip(condition)
    local remote_addr = ngx.var.remote_addr
    return _M.test_var(condition, remote_addr)
end

function _M.test_ua(condition)
    local http_user_agent = ngx.var.http_user_agent
    return _M.test_var(condition, http_user_agent)
end

function _M.test_referer(condition)
    local http_referer = ngx.var.http_referer
    return _M.test_var(condition, http_referer)
end

function _M.test_host(condition)
    local hostname = ngx.var.host
    return _M.test_var(condition, hostname)
end


function _M.test_method(condition)
    local method = ngx.req.get_method()
    if condition and condition.value then
        condition.value = slower(condition.value)
    end

    return _M.test_var(condition, method)
end

function _M.test_post_params(condition)
    local headers = ngx.req.get_headers()
    local header = headers['Content-Type']
    if header then
        local is_multipart = sfind(header, "multipart")
        if is_multipart and is_multipart > 0 then
            return false
        end
    end

    ngx.req.read_body()
    local post_params, err = ngx.req.get_post_args()
    if not post_params or err then
        ngx.log(ngx.ERR, "failed to get post args: ", err)
        return false
    end

    return _M.test_var(condition, post_params[condition.name])
end


function _M.test_var(condition, var)
    local operator = condition.operator
    local value = condition.value

    if operator == "=" then
        if var == value then
            return true
        end
    elseif operator == "!=" then
        if var ~= value then
            return true
        end
    elseif operator == 'match' then
        if var ~= nil and ngx.re.find(var, value, 'isjo') ~= nil then
            return true
        end
    elseif operator == 'not_match' then
        if var == nil or ngx.re.find(var, value, 'isjo') == nil then
            return true
        end
    elseif operator == '!' then
        if var == nil then
            return true
        end

    elseif operator == '>' then
        if var ~= nil and value ~= nil then
            value = tonumber(value)
            var = tonumber(var)
            if var and value and var > value then
                return true
            end
        end
    elseif operator == '>=' then
        if var ~= nil and value ~= nil then
            value = tonumber(value)
            var = tonumber(var)
            if var and value and var >= value then
                return true
            end
        end
    elseif operator == '<' then
        if var ~= nil and value ~= nil then
            value = tonumber(value)
            var = tonumber(var)
            if var and value and var < value then
                return true
            end
        end
    elseif operator == '<=' then
        if var ~= nil and value ~= nil then
            value = tonumber(value)
            var = tonumber(var)
            if var and value and var <= value then
                return true
            end
        end
    end

    return false
end

return _M
