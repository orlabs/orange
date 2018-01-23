local DB = require("dashboard.model.db")

return function(config)

    local node_model = {}
    local mysql_config = config.store_mysql
    local db = DB:new(mysql_config)

    local table_name = 'persist_log'

    function node_model:get_stat(limit, group_by_day)

        local result, err

        if group_by_day then
            result, err = db:query(
                "SELECT stat_time,ip,SUM(request_2xx) request_2xx,SUM(request_3xx) request_3xx,SUM(request_4xx) request_4xx,SUM(request_5xx) request_5xx,SUM(total_request_count) total_request_count,SUM(total_success_request_count) total_success_request_count,SUM(traffic_read) traffic_read,SUM(traffic_write) traffic_write,SUM(total_request_time) total_request_time " ..
                "FROM (SELECT DATE(stat_time) stat_time,ip,SUM(request_2xx) request_2xx,SUM(request_3xx) request_3xx,SUM(request_4xx) request_4xx,SUM(request_5xx) request_5xx,SUM(total_request_count) total_request_count,SUM(total_success_request_count) total_success_request_count,SUM(traffic_read) traffic_read,SUM(traffic_write) traffic_write,SUM(total_request_time) total_request_time FROM " .. table_name .. " " ..
                "GROUP BY stat_time ) T GROUP BY stat_time ORDER BY stat_time DESC LIMIT ? ", { limit }
            )
        else
            result, err = db:query("" ..
            " SELECT op_time, " ..
            " DATE_FORMAT(stat_time, '%Y-%m-%d %h:%i') as stat_time, " ..
            " SUM(request_2xx) as request_2xx," ..
            " sum(request_3xx) as request_3xx," ..
            " sum(request_4xx) as request_4xx," ..
            " sum(request_5xx) as request_5xx," ..
            " sum(total_request_count) as total_request_count," ..
            " sum(total_success_request_count) as total_success_request_count," ..
            " sum(traffic_read) as traffic_read," ..
            " sum(traffic_write) as traffic_write," ..
            " sum(total_request_time) as total_request_time" ..
            " FROM " .. table_name ..
            " GROUP BY stat_time" ..
            " ORDER BY stat_time DESC LIMIT ?", { limit })
        end

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    function node_model:get_stat_by_ip(ip, limit, group_by_day)

        local result, err

        if group_by_day then
            result, err = db:query(
                "SELECT stat_time,ip,SUM(request_2xx) request_2xx,SUM(request_3xx) request_3xx,SUM(request_4xx) request_4xx,SUM(request_5xx) request_5xx,SUM(total_request_count) total_request_count,SUM(total_success_request_count) total_success_request_count,SUM(traffic_read) traffic_read,SUM(traffic_write) traffic_write,SUM(total_request_time) total_request_time " ..
                "FROM (SELECT DATE(stat_time) stat_time,ip,SUM(request_2xx) request_2xx,SUM(request_3xx) request_3xx,SUM(request_4xx) request_4xx,SUM(request_5xx) request_5xx,SUM(total_request_count) total_request_count,SUM(total_success_request_count) total_success_request_count,SUM(traffic_read) traffic_read,SUM(traffic_write) traffic_write,SUM(total_request_time) total_request_time FROM " .. table_name .. " " ..
                "GROUP BY stat_time HAVING ip = ?) T GROUP BY stat_time ORDER BY stat_time DESC LIMIT ? ", { ip, limit })
        else
            result, err = db:query("SELECT * from " .. table_name .. " WHERE ip = ? ORDER BY stat_time DESC LIMIT ?", { ip, limit })
        end

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    return node_model
end

