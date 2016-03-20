local _M = {}

function _M.test(condition)
    local test_type = condition.type
    if not test_type or not condition then
        return false
    end

    local pass = false
    if test_type == "URI" then
        pass = _M.test_uri(condition)
    elseif test_type == "Header" then
        pass = _M.test_header(condition)
    elseif test_type == "IP" then
        pass = _M.test_ip(condition)
    elseif test_type == "UserAgent" then
        pass = _M.test_ua(condition)
    elseif test_type == "Method" then
        pass = _M.test_method(condition)
    elseif test_type == "Args" then
        pass = _M.test_args(condition)
    elseif test_type == "Referer" then
        pass = _M.test_referer(condition)
    elseif test_type == "Host" then
        pass = _M.test_host(condition)
    end

    return pass
end


function _M.test_uri(condition)
    local uri = ngx.var.uri;
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
    local http_user_agent = ngx.var.http_user_agent;
    return _M.test_var(condition, http_user_agent)
end

function _M.test_referer(condition)
    local http_referer = ngx.var.http_referer;
    return _M.test_var(condition, http_referer)
end

function _M.test_host(condition)
    local hostname = ngx.var.host
    return _M.test_var(condition, hostname)
end


function _M.test_method(condition)
    return false
end

function _M.test_args(condition)

    local target_arg_re = condition['name']
    local find = ngx.find
    local test_var = _M.test_var

    --handle args behind uri
    for k, v in pairs(ngx.req.get_uri_args()) do
        if type(v) == "table" then
            for arg_idx, arg_value in ipairs(v) do
                if target_arg_re == nil or find(k, target_arg_re) ~= nil then
                    if test_var(condition, arg_value) == true then
                        return true
                    end
                end
            end
        elseif type(v) == "string" then
            if target_arg_re == nil or find(k, target_arg_re) ~= nil then
                if test_var(condition, v) == true then
                    return true
                end
            end
        end
    end


    ngx.req.read_body()
    --ensure body has not be cached into temp file
    if ngx.req.get_body_file() ~= nil then
        return false
    end

    local body_args, err = ngx.req.get_post_args()
    if body_args == nil then
        ngx.say("failed to get post args: ", err)
        return false
    end

    --check args in body
    for k, v in pairs(body_args) do
        if type(v) == "table" then
            for arg_idx, arg_value in ipairs(v) do
                if target_arg_re == nil or find(k, target_arg_re) ~= nil then
                    if test_var(condition, arg_value) == true then
                        return true
                    end
                end
            end
        elseif type(v) == "string" then
            if target_arg_re == nil or find(k, target_arg_re) ~= nil then
                if test_var(condition, v) == true then
                    return true
                end
            end
        end
    end

    return false
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
    elseif operator == '≈' then
        if var ~= nil and ngx.re.find(var, value, 'isjo') ~= nil then
            return true
        end
    elseif operator == '!≈' then
        if var == nil or ngx.re.find(var, value, 'isjo') == nil then
            return true
        end
    elseif operator == '!' then
        if var == nil then
            return true
        end
    end

    return false
end

return _M
