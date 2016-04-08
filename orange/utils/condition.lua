local sfind = string.find
local slower = string.lower
local type = type
local ngx_re_find = ngx.re.find

local function assert_condition(real, operator, expected)
    if operator == 'match' then
        if real ~= nil and ngx_re_find(real, expected, 'isjo') ~= nil then
            return true
        end
    elseif operator == 'not_match' then
        if real == nil or ngx_re_find(real, expected, 'isjo') == nil then
            return true
        end
    elseif operator == "=" then
        if real == expected then
            return true
        end
    elseif operator == "!=" then
        if real ~= expected then
            return true
        end
    elseif operator == '!' then
        if real == nil then
            return true
        end
    elseif operator == '>' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real > expected then
                return true
            end
        end
    elseif operator == '>=' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real >= expected then
                return true
            end
        end
    elseif operator == '<' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real < expected then
                return true
            end
        end
    elseif operator == '<=' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real <= expected then
                return true
            end
        end
    end

    return false
end



local _M = {}

function _M.judge(condition)
    local condition_type = condition and condition.type
    if not condition_type then
        return false
    end

    local operator = condition.operator
    local expected = condition.value
    local pass = false

    if condition_type == "URI" then
        local uri = ngx.var.uri
        pass = assert_condition(uri, operator, expected)
    elseif condition_type == "Query" then
        local query = ngx.req.get_uri_args()
        pass = assert_condition(query[condition.name], operator, expected)
    elseif condition_type == "Header" then
        local headers = ngx.req.get_headers()
        pass = assert_condition(headers[condition.name], operator, expected)
    elseif condition_type == "IP" then
        local remote_addr = ngx.var.remote_addr
        pass = assert_condition(remote_addr, operator, expected)
    elseif condition_type == "UserAgent" then
        local http_user_agent = ngx.var.http_user_agent
        pass = assert_condition(http_user_agent, operator, expected)
    elseif condition_type == "Method" then
        local method = ngx.req.get_method()
        if method then
            method = slower(method)
        end
        if expected and type(expected) == "string" then
            expected = slower(expected)
        else
            expected = ""
        end
        pass = assert_condition(method, operator, expected)
    elseif condition_type == "PostParams" then
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
            ngx.log(ngx.ERR, "[Condition Judge]failed to get post args: ", err)
            return false
        end

        pass = assert_condition(post_params[condition.name], operator, expected)
    elseif condition_type == "Referer" then
        local http_referer = ngx.var.http_referer
        pass = assert_condition(http_referer, operator, expected)
    elseif condition_type == "Host" then
        local host = ngx.var.host
        pass = assert_condition(host, operator, expected)
    end

    return pass
end


return _M
