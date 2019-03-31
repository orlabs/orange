local resty_consul = require('orange.lib.hamishforbes.lua-resty-consul.consul')
local orange = require("orange.orange")

local _M = {}

function _M.new()
    local cfg = orange.data.config.consul
    local consul = resty_consul:new({
        host = cfg.host,
        port = cfg.port,
    }) 

    consul.cfg = cfg
    return consul
end

function _M.get(key)
    local consul = _M.new()
    local res, err = consul:get('/kv/' .. key, {['X-Consul-Token'] = consul.cfg.token})
    if not res then
        ngx.log(ngx.ERR, err)
        return nil, err
    end

    for _,entry in ipairs(res) do
        if type(entry.Value) == "string" then
            local decoded = ngx.decode_base64(entry.Value)
            return decoded
        end
    end

    return nil, err
end

function _M.set(key, value)
    if value then
        value = json.encode(value)
    end

    local consul = _M.new()

    local res, err = consul:set('/kv/gateway' .. key, value)
    if not res then
        ngx.log(ngx.ERR, err)
    end
    return _M._set(key, value)
end

function _M.check_service(key, opts)
    --local consul = _M.new()
    local uri = "/health/service/" .. key
    local opt = {}
    if nil ~= opts and type(opts) == 'table' then
        opt = opts
    end

    local consul = _M.new()
    if nil ~= consul.cfg.token then
        opt['X-Consul-Token'] = consul.cfg.token
    end

    local res, err = consul:get(uri, opt)
    if not res then
        ngx.log(ngx.ERR, err)
        return nil, err
    end

    return res, err
end

function _M.create_selector(plugin, selector)
    return store:insert({
        sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
        params = { selector.id, json.encode(selector), "selector", selector.time }
    })
end

return _M
