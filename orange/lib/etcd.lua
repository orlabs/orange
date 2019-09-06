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

local function set(key, val, attr)
    local err
    val, err = encode_json(val)
    if not val then
        return nil, err
    end


    local prev_exist
    if attr.prev_exist ~= nil then
        prev_exist = attr.prev_exist and 'true' or 'false'
    end

    local dir
    if attr.dir then
        dir = attr.dir and 'true' or 'false'
    end

    local opts = {
        body = {
            ttl = attr.ttl,
            value = val,
            dir = dir,
        },
        query = {
            prevExist = prev_exist,
            prevIndex = attr.prev_index,
        }
    }

    -- todo: check arguments

    -- verify key
    key = normalize(key)
    if key == '/' then
        return nil, "key should not be a slash"
    end

    local res
    res, err = _request(attr.in_order and 'POST' or 'PUT',
        ops.endpoints.full_prefix .. key,
        opts, ops.timeout)
    if err then
        return nil, err
    end

    -- get
    if res.status < 300 and res.body.node and
        not res.body.node.dir then
        res.body.node.value, err = decode_json(res.body.node.value)
        if err then
            return nil, err
        end
    end

    return res
end

local function decode_dir_value(body_node)
    if not body_node.dir then
        return false
    end

    if type(body_node.nodes) ~= "table" then
        return false
    end

    local err
    for _, node in ipairs(body_node.nodes) do
        local val = node.value
        if type(val) == "string" then
            node.value, err = decode_json(val)
            if err then
                error("failed to decode info|" .. val)
            end
        end

        decode_dir_value(node)
    end

    return true
end

local function get(key, attr)
    local opts
    if attr then
        local attr_wait
        if attr.wait ~= nil then
            attr_wait = attr.wait and 'true' or 'false'
        end

        local attr_recursive
        if attr.recursive then
            attr_recursive = attr.recursive and 'true' or 'false'
        end

        opts = {
            query = {
                wait = attr_wait,
                waitIndex = attr.wait_index,
                recursive = attr_recursive,
                consistent = attr.consistent,   -- todo
            }
        }
    end
    local res, err = _request("GET",
        ops.endpoints.full_prefix .. normalize(key),
        opts, attr and attr.timeout or ops.timeout)
    if err then
        return nil, err
    end
    --for key, val in pairs(res) do
    --    ngx.log(ERR, "key==============================" .. key)
    --    ngx.log(ERR, "val==============================" .. type(val))
    --end

    -- readdir
    if attr and attr.dir then
        if res.status == 200 and res.body.node and
            not res.body.node.dir then
            res.body.node.dir = false
        end
    end

    if res.status == 200 and res.body.node then
        if not decode_dir_value(res.body.node) then
            local val = res.body.node.value
            if type(val) == "string" then
                res.body.node.value, err = decode_json(val)
                if err then
                    ngx.log(ERR, "failed to pass json, err:" .. err)
                    return nil, err
                end
            end
        end
    end
    return res
end

local function delete(key, attr)
    local val, err = attr.prev_value
    if val ~= nil and type(val) ~= "number" then
        val, err = encode_json(val)
        if not val then
            return nil, err
        end
    end

    local attr_dir
    if attr.dir then
        attr_dir = attr.dir and 'true' or 'false'
    end

    local attr_recursive
    if attr.recursive then
        attr_recursive = attr.recursive and 'true' or 'false'
    end

    local opts = {
        query = {
            dir = attr_dir,
            prevIndex = attr.prev_index,
            recursive = attr_recursive,
            prevValue = val,
        },
    }

    -- todo: check arguments
    return _request("DELETE",
        ops.endpoints.full_prefix .. normalize(key),
        opts, ops.timeout)
end

do

    function _M.get(ops, key)
        init_configurations(ops)
        if not typeof.string(key) then
            return nil, 'key must be string'
        end
        return get(key)
    end

    local attr = {}
    function _M.wait(self, key, modified_index, timeout)
        clear_tab(attr)
        attr.wait = true
        attr.wait_index = modified_index
        attr.timeout = timeout

        return get(self, key, attr)
    end

    function _M.readdir(self, key, recursive)
        clear_tab(attr)
        attr.dir = true
        attr.recursive = recursive

        return get(self, key, attr)
    end

    -- wait with recursive
    function _M.waitdir(self, key, modified_index, timeout)
        clear_tab(attr)
        attr.wait = true
        attr.dir = true
        attr.recursive = true
        attr.wait_index = modified_index
        attr.timeout = timeout

        return get(self, key, attr)
    end

    -- /version
    function _M.version(self)
        return _request('GET', ops.endpoints.version, nil, ops.timeout)
    end

    -- /stats
    function _M.stats_leader(self)
        return _request('GET', ops.endpoints.stats_leader, nil, ops.timeout)
    end

    function _M.stats_self(self)
        return _request('GET', ops.endpoints.stats_self, nil, ops.timeout)
    end

    function _M.stats_store(self)
        return _request('GET', ops.endpoints.stats_store, nil, ops.timeout)
    end

end -- do


do
    local attr = {}
    function _M.delete(ops, key, prev_val, modified_index)
        init_configurations(ops)
        clear_tab(attr)
        attr.prev_value = prev_val
        attr.prev_index = modified_index

        return delete(key, attr)
    end

    function _M.rmdir(ops, key, recursive)
        init_configurations(ops)
        clear_tab(attr)
        attr.dir = true
        attr.recursive = recursive

        return delete(key, attr)
    end

    function _M.set(ops, key, val, ttl)
        init_configurations(ops)
        clear_tab(attr)
        attr.ttl = ttl
        return set(key, val, attr)
    end

    -- set key-val and ttl if key does not exists (atomic create)
    function _M.setnx(self, key, val, ttl)
        clear_tab(attr)
        attr.ttl = ttl
        attr.prev_exist = false

        return set(self, key, val, attr)
    end

    -- set key-val and ttl if key is exists (update)
    function _M.setx(self, key, val, ttl, modified_index)
        clear_tab(attr)
        attr.ttl = ttl
        attr.prev_exist = true
        attr.prev_index = modified_index

        return set(self, key, val, attr)
    end

    -- dir
    function _M.mkdir(self, key, ttl)
        clear_tab(attr)
        attr.ttl = ttl
        attr.dir = true

        return set(self, key, nil, attr)
    end

    -- mkdir if not exists
    function _M.mkdirnx(self, key, ttl)
        clear_tab(attr)
        attr.ttl = ttl
        attr.dir = true
        attr.prev_exist = false

        return set(self, key, nil, attr)
    end

    -- in-order keys
    function _M.push(self, key, val, ttl)
        clear_tab(attr)
        attr.ttl = ttl
        attr.in_order = true

        return set(self, key, val, attr)
    end

end -- do


do
    local attr = {}

end -- do


return _M
