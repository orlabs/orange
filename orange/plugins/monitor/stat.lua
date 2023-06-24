local tonumber = tonumber
local _M = {}

local TOTAL_COUNT = "TOTAL_COUNT:"
local TRAFFIC_READ = "TRAFFIC_READ:"
local TRAFFIC_WRITE = "TRAFFIC_WRITE:"
local TOTAL_REQUEST_TIME = "TOTAL_REQUEST_TIME:"

local REQUEST_2XX = "REQUEST_2XX:"
local REQUEST_3XX = "REQUEST_3XX:"
local REQUEST_4XX = "REQUEST_4XX:"
local REQUEST_5XX = "REQUEST_5XX:"

local status = ngx.shared.monitor
local function safe_count(key, value, default_value)
    local newval, err = status:incr(key, value)
    if not newval or err then
        status:set(key, default_value or value)
    end
end


local _M = {}

function _M.get_one(key_suffix)
    local total_count, _ = status:get(TOTAL_COUNT .. key_suffix)
    total_count = total_count or 0

    local traffic_read, _ = status:get(TRAFFIC_READ .. key_suffix)
    traffic_read = traffic_read or 0

    local traffic_write, _ = status:get(TRAFFIC_WRITE .. key_suffix)
    traffic_write = traffic_write or 0

    local total_request_time, _ = status:get(TOTAL_REQUEST_TIME .. key_suffix)
    total_request_time = total_request_time or 0

    local average_request_time, average_traffic_read, average_traffix_write
    if total_count ~= 0 then
        average_request_time = total_request_time / total_count
        average_traffic_read = traffic_read / total_count
        average_traffix_write = traffic_write /total_count
    else
        average_request_time = 0
        average_traffic_read = 0
        average_traffix_write = 0
    end

    local request_2xx, _ = status:get(REQUEST_2XX .. key_suffix)
    request_2xx = request_2xx or 0

    local request_3xx, _ = status:get(REQUEST_3XX .. key_suffix)
    request_3xx = request_3xx or 0

    local request_4xx, _ = status:get(REQUEST_4XX .. key_suffix)
    request_4xx = request_4xx or 0

    local request_5xx, _ = status:get(REQUEST_5XX .. key_suffix)
    request_5xx = request_5xx or 0

    local result = {
        total_count = total_count,
        traffic_read = traffic_read,
        traffic_write = traffic_write,
        total_request_time = total_request_time,
        average_request_time = average_request_time,
        average_traffic_read = average_traffic_read,
        average_traffix_write = average_traffix_write,
        request_2xx = request_2xx,
        request_3xx = request_3xx,
        request_4xx = request_4xx,
        request_5xx = request_5xx
    }

    return result
end


function _M.count(key_suffix)
    if not key_suffix then
        return
    end

    local ngx_var = ngx.var
    safe_count(TOTAL_COUNT .. key_suffix, 1)

    local http_status = tonumber(ngx_var.status)
    if http_status >= 200 and http_status < 300 then
        safe_count(REQUEST_2XX .. key_suffix, 1)
    elseif http_status >= 300 and http_status < 400 then
        safe_count(REQUEST_3XX .. key_suffix, 1)
    elseif http_status >= 400 and http_status < 500 then
        safe_count(REQUEST_4XX .. key_suffix, 1)
    elseif http_status >= 500 and http_status < 600 then
        safe_count(REQUEST_5XX .. key_suffix, 1)
    end


    safe_count(TRAFFIC_READ .. key_suffix, tonumber(ngx_var.request_length))
    safe_count(TRAFFIC_WRITE .. key_suffix, tonumber(ngx_var.bytes_sent))
    safe_count(TOTAL_REQUEST_TIME .. key_suffix, ngx.now() - ngx.req.start_time())
end

function _M.get(key_suffix)
    return _M.get_one(key_suffix)
end

return _M
