-- https://github.com/ledgetech/lua-resty-http
local http = require "resty.http"
local typeof = require "typeof"
local encode_args = ngx.encode_args
local setmetatable = setmetatable
local decode_json, encode_json
do
    local cjson = require "cjson.safe"
    decode_json = cjson.decode
    encode_json = cjson.encode
end
local clear_tab = require "table.clear"
--local tab_nkeys = require "table.nkeys"
local split = require "ngx.re" .split
local concat_tab = table.concat
local tostring = tostring
local select = select
local ipairs = ipairs
local type = type
local error = error
local ERR = ngx.ERR


local _M = {}
local mt = { __index = _M }
local ops = {}

local normalize
do
    local items = {}
    local function concat(sep, ...)
        local argc = select('#', ...)
        clear_tab(items)
        local len = 0

        for i = 1, argc do
            local v = select(i, ...)
            if v ~= nil then
                len = len + 1
                items[len] = tostring(v)
            end
        end

        return concat_tab(items, sep);
    end


    local segs = {}
    function normalize(...)
        local path = concat('/', ...)
        local names = {}
        local err

        segs, err = split(path, [[/]], "jo", nil, nil, segs)
        if not segs then
            return nil, err
        end

        local len = 0
        for _, seg in ipairs(segs) do
            if seg == '..' then
                if len > 0 then
                    len = len - 1
                end

            elseif seg == '' or seg == '/' and names[len] == '/' then
                -- do nothing

            elseif seg ~= '.' then
                len = len + 1
                names[len] = seg
            end
        end

        return '/' .. concat_tab(names, '/', 1, len);
    end
end
_M.normalize = normalize

local function init_configurations(opts)
    if opts == nil then
        opts = {}

    elseif not typeof.table(opts) then
        return nil, 'opts must be table'
    end

    local timeout = opts.timeout or 5000    -- 5 sec
    --ngx.log(ERR, opts.host)
    local http_host = opts.host or "http://127.0.0.1:2379"
    local ttl = opts.ttl or -1
    local prefix = opts.prefix or "/v2/keys"

    if not typeof.uint(timeout) then
        return nil, 'opts.timeout must be unsigned integer'
    end

    if not typeof.string(http_host) then
        return nil, 'opts.host must be string'
    end

    if not typeof.int(ttl) then
        return nil, 'opts.ttl must be integer'
    end

    if not typeof.string(prefix) then
        return nil, 'opts.prefix must be string'
    end
    ops = {
        timeout = timeout,
        ttl = ttl,
        endpoints = {
            full_prefix = http_host .. normalize(prefix),
            http_host = http_host,
            prefix = prefix,
            version     = http_host .. '/version',
            stats_leader = http_host .. '/v2/stats/leader',
            stats_self   = http_host .. '/v2/stats/self',
            stats_store  = http_host .. '/v2/stats/store',
            keys        = http_host .. '/v2/keys',
        }
    }
end

function _M.new(opts)
    if opts == nil then
        opts = {}

    elseif not typeof.table(opts) then
        return nil, 'opts must be table'
    end

    local timeout = opts.timeout or 5000    -- 5 sec
    --ngx.log(ERR, opts.host)
    local http_host = opts.host or "http://127.0.0.1:2379"
    local ttl = opts.ttl or -1
    local prefix = opts.prefix or "/v2/keys"

    if not typeof.uint(timeout) then
        return nil, 'opts.timeout must be unsigned integer'
    end

    if not typeof.string(http_host) then
        return nil, 'opts.host must be string'
    end

    if not typeof.int(ttl) then
        return nil, 'opts.ttl must be integer'
    end

    if not typeof.string(prefix) then
        return nil, 'opts.prefix must be string'
    end
    local res = setmetatable({
        timeout = timeout,
        ttl = ttl,
        endpoints = {
            full_prefix = http_host .. normalize(prefix),
            http_host = http_host,
            prefix = prefix,
            version     = http_host .. '/version',
            stats_leader = http_host .. '/v2/stats/leader',
            stats_self   = http_host .. '/v2/stats/self',
            stats_store  = http_host .. '/v2/stats/store',
            keys        = http_host .. '/v2/keys',
        }
    },
        mt)
    ngx.log(ERR, http_host)
    return res
end

local content_type = {
    ["Content-Type"] = "application/x-www-form-urlencoded",
}

local function _request(method, uri, opts, timeout)
    local body
    --ngx.log(ERR, "METHOD ==================+++++++++++++++++=====================" .. method)
    --if opts and opts.body and tab_nkeys(opts.body) > 0 then
    if opts and opts.body then
        body = encode_args(opts.body)
    end

    --if opts and opts.query and tab_nkeys(opts.query) > 0 then
    if opts and opts.query then
        uri = uri .. '?' .. encode_args(opts.query)
    end
    --ngx.log(ERR, "URI***************************" .. uri)
    local http_cli, err = http.new()
    if err then
        return nil, err
    end

    if timeout then
        http_cli:set_timeout(timeout * 1000)
    end

    local res
    res, err = http_cli:request_uri(uri, {
        method = method,
        body = body,
        headers = content_type,
    })

    if err then
        return nil, err
    end

    if res.status >= 500 then
        return nil, "invalid response code: " .. res.status
    end

    if not typeof.string(res.body) then
        return res
    end

    res.body = decode_json(res.body)
    return res
end

