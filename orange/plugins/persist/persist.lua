local socket = require("socket")
local status = ngx.shared.status

local KEY_TOTAL_COUNT = "TOTAL_REQUEST_COUNT"
local KEY_TOTAL_SUCCESS_COUNT = "TOTAL_SUCCESS_REQUEST_COUNT"
local KEY_TRAFFIC_READ = "TRAFFIC_READ"
local KEY_TRAFFIC_WRITE = "TRAFFIC_WRITE"
local KEY_TOTAL_REQUEST_TIME = "TOTAL_REQUEST_TIME"

local KEY_REQUEST_2XX = "REQUEST_2XX"
local KEY_REQUEST_3XX = "REQUEST_3XX"
local KEY_REQUEST_4XX = "REQUEST_4XX"
local KEY_REQUEST_5XX = "REQUEST_5XX"

function toint(x)
    local y = math.ceil(x)
    if y == x then
        return x
    else
        return y - 1
    end
end

local _M = {}

function _M.init(config)
    ngx.log(ngx.ERR, "persist init")

    local node_ip = _M.get_ip()
    local delay = 60
    local handler
    handler = function()
        -- 暂存
        local request_2xx = status:get(KEY_REQUEST_2XX)
        local request_3xx = status:get(KEY_REQUEST_3XX)
        local request_4xx = status:get(KEY_REQUEST_4XX)
        local request_5xx = status:get(KEY_REQUEST_5XX)
        local total_count = status:get(KEY_TOTAL_COUNT)
        local total_success_count = status:get(KEY_TOTAL_SUCCESS_COUNT)
        local traffic_read = status:get(KEY_TRAFFIC_READ)
        local traffic_write = status:get(KEY_TRAFFIC_WRITE)
        local total_request_time = status:get(KEY_TOTAL_REQUEST_TIME)

        -- 清空计数
        status:set(KEY_REQUEST_2XX, 0)
        status:set(KEY_REQUEST_3XX, 0)
        status:set(KEY_REQUEST_4XX, 0)
        status:set(KEY_REQUEST_5XX, 0)
        status:set(KEY_TOTAL_COUNT, 0)
        status:set(KEY_TOTAL_SUCCESS_COUNT, 0)
        status:set(KEY_TRAFFIC_READ, 0)
        status:set(KEY_TRAFFIC_WRITE, 0)
        status:set(KEY_TOTAL_REQUEST_TIME, 0)

        -- 存储统计
        local stat_key = node_ip .. '-' .. toint(ngx.now())
        local result, err = config.store:query({
            sql = "INSERT cluster_node_stat " ..
                "(ip, `key`, request_2xx, request_3xx, request_4xx, request_5xx, total_request_count, total_success_request_count, traffic_read, traffic_write, total_request_time) " ..
                "VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            params = {
                node_ip,
                stat_key,
                request_2xx,
                request_3xx,
                request_4xx,
                request_5xx,
                total_count,
                total_success_count,
                traffic_read,
                traffic_write,
                total_request_time
            }
        })

        if not result or err then
            ngx.log(ngx.ERR, "ERR", err)
        end

        local ok, err = ngx.timer.at(delay, handler)
        if not ok then
            ngx.log(ngx.ERR, "failed to create the timer: ", err)
            return
        end
    end

    local ok, err = ngx.timer.at(delay, handler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

-- 获取 IP
local function get_ip_by_hostname(hostname)
    local _, resolved = socket.dns.toip(hostname)
    local list_tab = {}
    for _, v in ipairs(resolved.ip) do
        table.insert(list_tab, v)
    end
    return unpack(list_tab)
end

function _M.get_ip()
    if not _M.ip then
        _M.ip = get_ip_by_hostname(socket.dns.gethostname())
    end
    return _M.ip
end

return _M
