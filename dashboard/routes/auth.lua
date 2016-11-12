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
    local auth_router = lor:Router()
    local user_model = require("dashboard.model.user")(config)

    auth_router:get("/login", function(req, res, next)
        res:render("login")
    end)

    auth_router:post("/login", function(req, res, next)
        local username = req.body.username
        local password = req.body.password

        if not username or not password or username == "" or password == "" then
            return res:json({
                success = false,
                msg = "用户名和密码不得为空."
            })
        end

        local isExist = false
        local userid = 0

        password = encode(password .. "#" .. pwd_secret)
        --ngx.say(username.. "#" ..password)
        local result, err = user_model:query(username, password)

        local user = {}
        if result and not err then
            if result and #result == 1 then
                isExist = true
                user = result[1] 
                userid = user.id
            end
        else
            isExist = false
        end

        if isExist == true then
            local is_admin = false
            if user.is_admin == 1 then
                ngx.log(ngx.INFO, "管理员[", user.username, "]登录")
                is_admin = true
            else
                ngx.log(ngx.INFO, "普通用户[", user.username, "]登录")
            end

            req.session.set("user", {
                username = username,
                is_admin = is_admin,
                userid = userid,
                create_time = user.create_time or ""
            })
            return res:json({
                success = true,
                msg = "登录成功."
            })
        else
            return res:json({
                success = false,
                msg = "用户名或密码错误，请检查!"
            })
        end
    end)


    auth_router:get("/logout", function(req, res, next)
        res.locals.login = false
        res.locals.is_admin = false
        res.locals.username = ""
        res.locals.userid = 0
        res.locals.create_time = ""
        req.session.destroy()
        res:redirect("/login")
    end)


    return auth_router
end



