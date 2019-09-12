local store = context.store

return function(config)
    local user_model = {}
    function user_model:new(username, password, enable)
        return  store:user_new(username, password, enable)
    end

    function user_model:query(username, password)
        return store:user_query(username, password)
    end

    function user_model:query_all()
        return store:user_query_all()
    end

    --@unused
    function user_model:query_by_id(id)
        local result, err = self.db:query("select * from dashboard_user where id=?", {tonumber(id)})
        if not result or err or type(result) ~= "table" or #result ~=1 then
            return nil, err
        else
            return result[1], err
        end
    end

    -- return user, err
    function user_model:query_by_username(username)
        return store:user_query_by_username(username)
    end

    function user_model:update_enable(username, enable)
        return store:user_update_enable(username, enable)
    end

    function user_model:update_pwd_and_enable(username, pwd, enable)
        return store:user_update_pwd_and_enable(username, pwd, enable)
    end

    function user_model:delete(username)
        store:user_delete(username)
    end

    return user_model
end

