local DB = require("dashboard.model.db")


return function(config)
    local user_model = {}
    local mysql_config = config.store_mysql
    local db = DB:new(mysql_config)

    function user_model:new(username, password, enable)
        return db:query("insert into dashboard_user(username, password, enable) values(?,?,?)",
                {username, password, enable})
    end

    function user_model:query(username, password)
       local res, err =  db:query("select * from dashboard_user where username=? and password=?", {username, password})
       return res, err
    end

    function user_model:query_all()
        local result, err =  db:query("select id, username, is_admin, create_time, enable from dashboard_user order by id asc")
        if not result or err or type(result) ~= "table" or #result < 1 then
            return nil, err
        else
            return result, err
        end
    end

    function user_model:query_by_id(id)
        local result, err =  db:query("select * from dashboard_user where id=?", {tonumber(id)})
        if not result or err or type(result) ~= "table" or #result ~=1 then
            return nil, err
        else
            return result[1], err
        end
    end

    -- return user, err
    function user_model:query_by_username(username)
        local res, err =  db:query("select * from dashboard_user where username=? limit 1", {username})
        if not res or err or type(res) ~= "table" or #res ~=1 then
            return nil, err or "error"
        end

        return res[1], err
    end

    function user_model:update_enable(userid, enable)
        local res, err = db:query("update dashboard_user set enable=? where id=?", {tonumber(enable), tonumber(userid)})
        if not res or err then
            return false
        else
            return true
        end
    end

    function user_model:update_pwd_and_enable(userid, pwd, enable)
        local res, err = db:query("update dashboard_user set password=?, enable=? where id=?", {pwd, tonumber(enable), tonumber(userid)})
        if not res or err then
            return false
        else
            return true
        end
    end

    function user_model:delete(userid)
        local res, err = db:query("delete from dashboard_user where id=?", {tonumber(userid)})
        if not res or err then
            return false
        else
            return true
        end
    end

    return user_model
end

