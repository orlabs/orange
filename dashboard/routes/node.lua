local pairs = pairs
local smatch = string.match
local slen = string.len
local http = require("resty.http")
local encode_base64 = ngx.encode_base64
local string_format = string.format
local lor = require("lor.index")


-- 节点同步
local function sync(nodes, plugs)

    results = {}

    for i, node in pairs(nodes) do
        if node.ip and node.port and node.api_username and node.api_password then

            node_result = {
                name = node.name,
                ip = node.ip,
                result = {}
            }

            for j, plug in pairs(plugs) do

                if plug ~= 'stat' then
                    local httpc = http.new()

                    local url = string_format("http://%s:%s", node.ip, node.port)
                    local authorization = encode_base64(string_format("%s:%s", node.api_username, node.api_password))
                    local path = string_format('/%s/sync', plug)

                    ngx.log(ngx.INFO, url .. path)

                    local resp, err = httpc:request_uri(url, {
                        method = "POST",
                        path = path,
                        headers = {
                            ["Authorization"] = authorization
                        }
                    })

                    if not resp then
                        ngx.log(ngx.ERR, err)
                        return
                    end

                    ngx.log(ngx.INFO, resp.body)

                    table.insert(node_result.result, {
                        plug = plug,
                        status = resp.status
                    })

                    httpc:close()
                end
            end
        end

        table.insert(results, node_result)
    end

    return results
end


return function(config, store)
    local node_router = lor:Router()
    local node_model = require("dashboard.model.node")(config)

    node_router:get("/node/manage", function(req, res, next)
        res:render("node")
    end)

    node_router:get("/nodes", function(req, res, next)
        return res:json({
            success = true,
            data = {
                nodes = node_model:query_all(),
                plugins = config.plugins
            }
        })
    end)

    node_router:post("/node/new", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许创建节点."
            })
        end

        local name = req.body.name
        local ip = req.body.ip
        local port = tonumber(req.body.port)
        local api_username = req.body.api_username
        local api_password = req.body.api_password

        -- name
        local pattern = "^[a-zA-Z][0-9a-zA-Z_]+$"
        local match, err = smatch(name, pattern)

        if not name or not ip or name == "" or ip == "" then
            return res:json({
                success = false,
                msg = "节点名和IP不得为空."
            })
        end

        local name_len = slen(name)
        local ip_len = slen(ip)

        if name_len < 1 or name_len > 20 then
            return res:json({
                success = false,
                msg = "节点名长度应为1~20位."
            })
        end

        if not match then
            return res:json({
                success = false,
                msg = "节点名只能输入字母、下划线、数字，必须以字母开头."
            })
        end

        -- ip
        if ip_len < 7 and ip_len > 15 then
            return res:json({
                success = false,
                msg = "IP 长度应为 7-15 位."
            })
        end

        -- port
        if port < 1 or port > 65535 then
            return json:json({
                success =false,
                msg = "端口号为 1~65535 间的数字"
            })
        end


        -- check ip
        local result, err = node_model:query_by_ip(ip)
        local isExist = false
        if result and not err then
            isExist = true
        end

        if isExist == true then
            return res:json({
                success = false,
                msg = "该节点 IP 已添加到节点集群中"
            })
        else
            -- save node info to db
            local result, err = node_model:new(name, ip, port, api_username, api_password)
            if result and not err then
                return res:json({
                    success = true,
                    msg = "新建节点成功.",
                    data = {
                        nodes = node_model:query_all()
                    }
                })
            else
                return res:json({
                    success = false,
                    msg = "新建节点失败."
                })
            end
        end
    end)

    node_router:post("/node/modify", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许修改节点."
            })
        end

        local id = req.body.id
        local name = req.body.name
        local ip = req.body.ip
        local port = tonumber(req.body.port)
        local api_username = req.body.api_username
        local api_password = req.body.api_password

        local pattern = "^[a-zA-Z][0-9a-zA-Z_]+$"
        local match, err = smatch(name, pattern)

        if not name or not ip or name == "" or ip == "" or port == "" then
            return res:json({
                success = false,
                msg = "节点名、IP、端口不得为空."
            })
        end

        -- name
        local name_len = slen(name)
        local ip_len = slen(ip)

        if name_len < 1 or name_len > 20 then
            return res:json({
                success = false,
                msg = "节点名长度应为1~20位."
            })
        end

        if not match then
            return res:json({
                success = false,
                msg = "节点名只能输入字母、下划线、数字，必须以字母开头."
            })
        end

        -- ip
        if ip_len < 7 and ip_len > 15 then
            return res:json({
                success = false,
                msg = "IP 长度应为 7-15 位."
            })
        end

        -- port
        if port < 1 or port > 65535 then
            return json:json({
                success =false,
                msg = "端口号为 1~65535 间的数字"
            })
        end

        -- update node info to db
        local result = node_model:update_node(id, name, ip, port, api_username, api_password)
        if result then
            return res:json({
                success = true,
                msg = "修改节点成功.",
                data = {
                    nodes = node_model:query_all()
                }
            })
        else
            return res:json({
                success = false,
                msg = "修改节点失败."
            })
        end
    end)

    node_router:post("/node/delete", function(req, res, next)
        local is_admin = false

        if req and req.session and req.session.get("user") then
            is_admin = req.session.get('user').is_admin
        end

        if not is_admin then
            return res:json({
                success = false,
                msg = "您的身份不是管理员，不允许删除节点."
            })
        end

        local id = req.body.id
        if not id then
            return res:json({
                success = false,
                msg = "节点id不能为空"
            })
        end

        local result = node_model:delete(id)
        if result then
            return res:json({
                success = true,
                msg = "删除节点成功.",
                data = {
                    nodes = node_model:query_all()
                }
            })
        else
            return res:json({
                success = false,
                msg = "删除节点失败."
            })
        end
    end)

    node_router:post("/node/sync", function(req, res, next)

        ngx.log(ngx.INFO, "sync configure to orange nodes")

        local nodes = node_model:query_all()

        local plugs = config.plugins

        local results = sync(nodes, plugs)

        return res:json({
            success = true,
            msg = "同步已提交",
            results = results
        })
    end)



    return node_router
end
