local DB = require("dashboard.model.db")

return function(config)
    local node_model = {}
    local mysql_config = config.store_mysql
    local db = DB:new(mysql_config)

    function node_model:new(name, ip, port, api_username, api_password)
        return db:query("insert into node(name,ip,port,api_username,api_password) values(?,?,?,?,?)",
            { name, ip, port, api_username, api_password })
    end

    function node_model:query_all()
        local result, err = db:query("select * from node order by ip asc")
        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    function node_model:query_by_id(id)
        local result, err = db:query("select * from node where id=?", { tonumber(id) })
        if not result or err or type(result) ~= "table" or #result ~= 1 then
            return nil, err
        else
            return result[1], err
        end
    end

    function node_model:query_by_ip(id)
        local result, err = db:query("select * from node where ip=?", { id })
        if not result or err or type(result) ~= "table" or #result ~= 1 then
            return nil, err
        else
            return result[1], err
        end
    end

    function node_model:update_node(id, name, ip, port, api_username, api_password)
        local res, err = db:query("update node set name=?,ip=?,port=?,api_username=?,api_password=? where id=?", { name, ip, port, api_username, api_password, tonumber(id) })
        if not res or err then
            return false
        else
            return true
        end
    end

    function node_model:delete(id)
        local res, err = db:query("delete from node where id=?", { tonumber(id) })
        if not res or err then
            return false
        else
            return true
        end
    end

    return node_model
end

