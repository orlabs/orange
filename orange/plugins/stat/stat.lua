local tonumber = tonumber

local STAT_LOCK = "STAT_LOCK"
local KEY_START_TIME = "START_TIME"
local KEY_TOTAL_COUNT = "TOTAL_REQUEST_COUNT"
local KEY_TOTAL_SUCCESS_COUNT = "TOTAL_SUCCESS_REQUEST_COUNT"
local KEY_TRAFFIC_READ = "TRAFFIC_READ"
local KEY_TRAFFIC_WRITE = "TRAFFIC_WRITE"
local KEY_TOTAL_REQUEST_TIME = "TOTAL_REQUEST_TIME"

local KEY_REQUEST_2XX = "REQUEST_2XX"
local KEY_REQUEST_3XX = "REQUEST_3XX"
local KEY_REQUEST_4XX = "REQUEST_4XX"
local KEY_REQUEST_5XX = "REQUEST_5XX"
local redis = require("orange.plugins.base_redis")
local status = "orange_stat"

local orange_version = require("orange/version")

local _M = {}

function _M.init()
    local res, err = redis.setnx(status, STAT_LOCK, true, -1)
    if res and (not res == 0) then
        -- ngx.time() 是 OpenResty 提供的一个函数，用于获取当前时间戳。它返回的是一个整数
        redis.set(status, KEY_START_TIME, ngx.time())

        redis.set(status, KEY_TOTAL_COUNT, 0)
        redis.set(status, KEY_TOTAL_SUCCESS_COUNT, 0)

        redis.set(status, KEY_TRAFFIC_READ, 0)
        redis.set(status, KEY_TRAFFIC_WRITE, 0)

        redis.set(status, KEY_TOTAL_REQUEST_TIME, 0)

        redis.set(status, KEY_REQUEST_2XX, 0)
        redis.set(status, KEY_REQUEST_3XX, 0)
        redis.set(status, KEY_REQUEST_4XX, 0)
        redis.set(status, KEY_REQUEST_5XX, 0)
    end
end

function _M.log()
    local ngx_var = ngx.var
    redis.incr(status, KEY_TOTAL_COUNT, 1)

    local http_status = tonumber(ngx_var.status)

    if http_status < 400 then
        redis.incr(status, KEY_TOTAL_SUCCESS_COUNT, 1)
    end

    if http_status >= 200 and http_status < 300 then
        redis.incr(status, KEY_REQUEST_2XX, 1)
    elseif http_status >= 300 and http_status < 400 then
        redis.incr(status, KEY_REQUEST_3XX, 1)
    elseif http_status >= 400 and http_status < 500 then
        redis.incr(status, KEY_REQUEST_4XX, 1)
    elseif http_status >= 500 and http_status < 600 then
        redis.incr(status, KEY_REQUEST_5XX, 1)
    end


    redis.incr(status, KEY_TRAFFIC_READ, ngx_var.request_length)
    redis.incr(status, KEY_TRAFFIC_WRITE, ngx_var.bytes_sent)

    local request_time = ngx.now() - ngx.req.start_time()
    redis.incr(status, KEY_TOTAL_REQUEST_TIME, request_time)
end

function _M.stat()
    local ngx_lua_version = ngx.config.ngx_lua_version
    local result = {
        nginx_version = ngx.var.nginx_version,
        ngx_lua_version = math.floor(ngx_lua_version / 1000000) .. '.' .. math.floor(ngx_lua_version / 1000) ..'.' .. math.floor(ngx_lua_version % 1000),
        orange_version = orange_version,
        address = ngx.var.server_addr,
        worker_count = ngx.worker.count(),
        timestamp = ngx.time(),
        load_timestamp = redis.get(status, KEY_START_TIME),
        ngx_prefix = ngx.config.prefix(),



        start_time = redis.get(status, KEY_START_TIME),
        total_count = redis.get(status, KEY_TOTAL_COUNT),
        total_success_count = redis.get(status, KEY_TOTAL_SUCCESS_COUNT),
        traffic_read = redis.get(status, KEY_TRAFFIC_READ),
        traffic_write = redis.get(status, KEY_TRAFFIC_WRITE),
        total_request_time = math.floor(redis.get(status, KEY_TOTAL_REQUEST_TIME)),

        request_2xx = redis.get(status, KEY_REQUEST_2XX),
        request_3xx = redis.get(status, KEY_REQUEST_3XX),
        request_4xx = redis.get(status, KEY_REQUEST_4XX),
        request_5xx = redis.get(status, KEY_REQUEST_5XX),

        con_active = ngx.var.connections_active,
        con_rw = ngx.var.connections_reading + ngx.var.connections_writing,
        con_reading = ngx.var.connections_reading,
        con_writing = ngx.var.connections_writing,
        con_idle = ngx.var.connections_waiting
    }

    return result
end


return _M
