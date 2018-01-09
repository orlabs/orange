local DB = require("dashboard.model.db")

return function(config)

    local node_model = {}
    local mysql_config = config.store_mysql
    local db = DB:new(mysql_config)

    local table_name = 'cluster_node_stat'

    function node_model:get_stat(limit)

        local result, err = db:query("select op_time,sum(request_2xx) as request_2xx,sum(request_3xx) as request_3xx," ..
            " sum(request_4xx) as request_4xx," ..
            " sum(request_5xx) as request_5xx," ..
            " sum(total_request_count) as total_request_count," ..
            " sum(total_success_request_count) as total_success_request_count," ..
            " sum(traffic_read) as traffic_read," ..
            " sum(traffic_write) as traffic_write," ..
            " sum(total_request_time) as total_request_time" ..
            " from " .. table_name ..
            " group by minute(op_time)" ..
            " order by op_time asc limit ?", { limit })

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    function node_model:get_stat_by_ip(ip, limit)

        local result, err = db:query("select * from " .. table_name .. " where ip = ? order by op_time asc limit ?", { ip, limit })

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    return node_model
end

