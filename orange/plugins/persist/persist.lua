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

local function setinterval(callback, interval)

    local handler
    handler = function()
        if type(callback) == 'function' then
            callback()
        end

        local ok, err = ngx.timer.at(interval, handler)
        if not ok then
            ngx.log(ngx.ERR, "failed to create the timer: ", err)
            return
        end
    end

    local ok, err = ngx.timer.at(interval, handler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

local function write_data(config)

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
    local node_ip = _M.get_ip()

    local now = ngx.now()
    local date_now = os.date('*t', now)
    local min = date_now.min

    local stat_time = string.format('%d-%d-%d %d:%d:00',
        date_now.year, date_now.month, date_now.day, date_now.hour, min)

    local result, err
    local table_name = 'persist_log'

    -- 是否存在
    result, err = config.store:query({
        sql = "SELECT stat_time FROM " .. table_name .. " WHERE stat_time = ? AND ip = ? LIMIT 1",
        params = { stat_time, node_ip }
    })

    if not result or err then
        ngx.log(ngx.ERR, " query has error ", err)
    else

        local params = {
            tonumber(request_2xx),
            tonumber(request_3xx),
            tonumber(request_4xx),
            tonumber(request_5xx),
            tonumber(total_count),
            tonumber(total_success_count),
            tonumber(traffic_read),
            tonumber(traffic_write),
            tonumber(total_request_time),
            stat_time,
            node_ip
        }

        if result and #result == 1 then
            result, err = config.store:query({
                sql = "UPDATE " .. table_name .. " SET " ..
                    " request_2xx = request_2xx + ?, " ..
                    " request_3xx = request_3xx + ?, " ..
                    " request_4xx = request_4xx + ?, " ..
                    " request_5xx = request_5xx + ?, " ..
                    " total_request_count = total_request_count + ?, " ..
                    " total_success_request_count = total_success_request_count + ?, " ..
                    " traffic_read = traffic_read + ?, " ..
                    " traffic_write = traffic_write + ?, " ..
                    " total_request_time = total_request_time + ? " ..
                    " WHERE stat_time = ? AND ip = ? ",
                params = params,
            })
        else
            result, err = config.store:query({
                sql = "INSERT " .. table_name .. " " ..
                    " (request_2xx, request_3xx, request_4xx, request_5xx, total_request_count, total_success_request_count, traffic_read, traffic_write, total_request_time, stat_time, ip) " ..
                    " VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                params = params
            })
        end

        if not result or err then
            ngx.log(ngx.ERR, " query has error ", err)
        end
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

function _M.init(config)
    ngx.log(ngx.ERR, "persist init worker")

    local interval = 60

    -- 单进程，只执行一次
    if ngx.worker.id() == 0 then

        local date_now = os.date('*t', ngx.time())
        local second = date_now.sec

        if second > 0 then
            -- 矫正统计写入
            ngx.timer.at(interval - 1 - second, function()

                write_data(config)

                -- 定时保存
                setinterval(function()
                    write_data(config)
                end, interval)
            end)
        else
            -- 定时保存
            setinterval(function()
                write_data(config)
            end, interval)
        end
    end
end

function _M.log(config)

end

function _M.get_ip()
    if not _M.ip then
        _M.ip = get_ip_by_hostname(socket.dns.gethostname())
    end
    return _M.ip
end

return _M
