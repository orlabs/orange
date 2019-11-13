local json = require("orange.utils.json")
local store = context.store

return function(config)
    local store_type = config.store

    local node_model = {}
    local table_name = 'cluster_node'
    local stat_table_name = 'cluster_node_stat'

    function node_model:new(name, ip, port, api_username, api_password)
        return store:node_new(name, ip, port, api_username, api_password)
    end

    function node_model:query_all()
        return store:node_query_all()
    end

    function node_model:get_stat(limit)
--[[        local result, err = db:query("select op_time,sum(request_2xx) as request_2xx,sum(request_3xx) as request_3xx," ..
            " sum(request_4xx) as request_4xx," ..
            " sum(request_5xx) as request_5xx," ..
            " sum(total_request_count) as total_request_count," ..
            " sum(total_success_request_count) as total_success_request_count," ..
            " sum(traffic_read) as traffic_read," ..
            " sum(traffic_write) as traffic_write," ..
            " sum(total_request_time) as total_request_time" ..
            " from " .. stat_table_name ..
            " group by minute(op_time)" ..
            " order by op_time asc limit ?", { limit })

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end]]
    end

    function node_model:get_stat_by_ip(ip, limit)
--[[        local result, err = db:query("select * from " .. stat_table_name .. " where ip = ? order by op_time asc limit ?", { ip, limit })

        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end]]
    end


    function node_model:query_by_id(id)
--[[        local result, err = db:query("select * from " .. table_name .. " where id=?", { tonumber(id) })
        if not result or err or type(result) ~= "table" or #result ~= 1 then
            return nil, err
        else
            return result[1], err
        end]]
    end

    function node_model:query_by_ip(ip, port)
        return store:node_query_by_ip(ip, port)
--[[        local result, err = db:query("select * from " .. table_name .. " where ip=?", { ip })
        if not result or err or type(result) ~= "table" or #result ~= 1 then
            return nil, err
        else
            return result[1], err
        end]]
    end

    function node_model:update_node(id, name, ip, port, api_username, api_password)
        return store:node_update_node(id, name, ip, port, api_username, api_password)
--[[        local res, err = db:query("update " .. table_name .. " set name=?,ip=?,port=?,api_username=?,api_password=? where id=?", { name, ip, port, api_username, api_password, tonumber(id) })
        if not res or err then
            return false
        else
            return true
        end]]
    end

    function node_model:update_node_status(id, status)
--[[        local res, err = db:query("update " .. table_name .. " set sync_status=? where id=?", { status, tonumber(id) })
        if not res or err then
            return false
        else
            return true
        end]]
    end

    function node_model:delete(id)
        return store:node_delete(id)
--[[        local res, err = db:query("delete from " .. table_name .. " where id=?", { tonumber(id) })
        if not res or err then
            return false
        else
            return true
        end]]
    end

    function node_model:remove_error_nodes()
--[[        local res, err = db:query("delete from " .. table_name .. " where sync_status=? ", { json.encode({ ERROR = false }) })
        if not res or err then
            return false
        else
            return true
        end]]
    end

    function node_model:registry(ip, port, credentials)
--[[        local local_node = self:query_by_ip(ip)

        if not local_node then
            self:new(ip, ip, port, credentials.username, credentials.password)
            local_node = self.query_by_ip(ip)
        end

        return local_node]]
    end

    return node_model
end

