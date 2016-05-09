local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slower = string.lower
local ssub = string.sub
local slen = string.len
local cjson = require("cjson")
local resty_sha256 = require("resty.sha256")
local str = require("resty.string")
local pwd_secret = "c29a95a6a375c5406b88ce6cdfea3d65"
local lor = require("lor.index")


local function encode(s)
    local sha256 = resty_sha256:new()
    sha256:update(s)
    local digest = sha256:final()
    return str.to_hex(digest)
end


return function(config, store)
    local admin_router = lor:Router()
    local user_model = require("dashboard.model.user")(config)

    admin_router:get("/user/manage", function(req, res, next)
        res:render("user_manage")
    end)

    admin_router:get("/users", function(req, res, next)
        return res:json({
            success = true,
            data = {
                users = user_model:query_all()
            }
        })
    end)

    admin_router:post("/user/new", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许创建用户."
            })
        end

        local username = req.body.username 
        local password = req.body.password
        local enable = req.body.enable

        local pattern = "^[a-zA-Z][0-9a-zA-Z_]+$"
        local match, err = smatch(username, pattern)

        if not username or not password or username == "" or password == "" then
            return res:json({
                success = false,
                msg = "用户名和密码不得为空."
            })
        end

        local username_len = slen(username)
        local password_len = slen(password)

        if username_len<4 or username_len>50 then
            return res:json({
                success = false,
                msg = "用户名长度应为4~50位."
            })
        end
        if password_len<6 or password_len>50 then
            return res:json({
                success = false,
                msg = "密码长度应为6~50位."
            })
        end

        if not match then
           return res:json({
                success = false,
                msg = "用户名只能输入字母、下划线、数字，必须以字母开头."
            })
        end

        local result, err = user_model:query_by_username(username)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == true then
            return res:json({
                success = false,
                msg = "用户名已被占用，请修改."
            })
        else
            password = encode(password .. "#" .. pwd_secret)
            local result, err = user_model:new(username, password, enable)
            if result and not err then
                return res:json({
                    success = true,
                    msg = "新建用户成功.",
                    data = {
                        users = user_model:query_all()
                    }
                })  
            else
                return res:json({
                    success = false,
                    msg = "新建用户失败."
                }) 
            end
        end
    end)

    admin_router:post("/user/modify", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许修改用户."
            })
        end

        local password = req.body.new_pwd
        local password_len = slen(password)
        

        local user_id = req.body.user_id
        if not user_id then
            return res:json({
                success = false,
                msg = "用户id不能为空"
            })
        end

        local enable = req.body.enable
        if not password or password=="" then -- 无需更改密码
            local result = user_model:update_enable(user_id, enable)
            if result then
                return res:json({
                    success = true,
                    msg = "修改用户成功.",
                    data = {
                        users = user_model:query_all()
                    }
                })  
            else
                return res:json({
                    success = false,
                    msg = "修改用户失败."
                }) 
            end
        else
            if password_len<6 or password_len>50 then
                return res:json({
                    success = false,
                    msg = "密码长度应为6~50位."
                })
            end

            password = encode(password .. "#" .. pwd_secret)
            local result = user_model:update_pwd_and_enable(user_id, password, enable)
            if result then
                return res:json({
                    success = true,
                    msg = "修改用户成功.",
                    data = {
                        users = user_model:query_all()
                    }
                })  
            else
                return res:json({
                    success = false,
                    msg = "修改用户失败."
                }) 
            end
        end
    end)

    admin_router:post("/user/delete", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许删除用户."
            })
        end

        local user_id = req.body.user_id
        if not user_id then
            return res:json({
                success = false,
                msg = "用户id不能为空"
            })
        end

        local result = user_model:delete(user_id)
        if result then
            return res:json({
                success = true,
                msg = "删除用户成功.",
                data = {
                    users = user_model:query_all()
                }
            })  
        else
            return res:json({
                success = false,
                msg = "删除用户失败."
            }) 
        end
        
    end)


    return admin_router
end



