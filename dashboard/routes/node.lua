local pairs = pairs
local smatch = string.match
local slen = string.len
local http = require("resty.http")
local json = require("orange.utils.json")
local encode_base64 = ngx.encode_base64
local string_format = string.format
local lor = require("lor.index")
local socket = require("socket")


return function(config, store)

    local node_router = lor:Router()
    local node_model = require("dashboard.model.node")(config)

    local function get_nodes()
        local nodes = node_model:query_all()

        if nodes then
            for _, node in pairs(nodes) do
                -- 格式化成 json 数据
                node.sync_status = json.decode(node.sync_status)
            end
        end

        return nodes
    end

    -- 获取 IP
    local function get_ip_by_hostname(hostname)
        local ip, resolved = socket.dns.toip(hostname)
        local ListTab = {}
        for k, v in ipairs(resolved.ip) do
            table.insert(ListTab, v)
        end
        return unpack(ListTab)
    end


    -- 节点同步
    local function sync_nodes(nodes, plugins)

        for _, node in pairs(nodes) do
            if node.ip and node.port and node.api_username and node.api_password then

                for _, plugin in pairs(plugins) do

                    if plugin ~= 'stat' and plugin ~= 'node' then

                        local httpc = http.new()

                        -- 设置超时时间 200 ms
                        httpc:set_timeout(200)

                        local url = string_format("http://%s:%s", node.ip, node.port)
                        local authorization = encode_base64(string_format("%s:%s", node.api_username, node.api_password))
                        local path = string_format('/%s/sync', plugin)

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
                            node.sync_status[plugin] = false
                        else
                            ngx.log(ngx.INFO, resp.body)
                            node.sync_status[plugin] = resp.status == 200
                        end

                        httpc:close()
                    end
                end

                -- 更新到数据库
                node_model:update_node_status(node.id, json.encode(node.sync_status))
            end
        end

        return get_nodes()
    end

    function node_router:registry()
        local local_ip = get_ip_by_hostname(socket.dns.gethostname())
        node_model:registry(local_ip, 7777, config.api.credentials[1])
    end

    node_router:get("/node/registry", function(req, res, next)

        node_router:registry()

        res:json({
            success = true,
            data = {}
        })
    end)

    node_router:get("/node/manage", function(req, res, next)
        node_router:registry()
        res:render("node")
    end)

    node_router:get("/nodes", function(req, res, next)
        return res:json({
            success = true,
            data = {
                nodes = get_nodes(),
            }
        })
    end)

    node_router:post("/node/new", function(req, res, next)

        local name = req.body.name
        local ip = req.body.ip
        local api_username = req.body.api_username
        local api_password = req.body.api_password

        -- name
        if not name or not ip or name == "" or ip == "" then
            return res:json({
                success = false,
                msg = "节点名和IP不得为空."
            })
        end

        local name_len = slen(name)
        if name_len < 1 or name_len > 20 then
            return res:json({
                success = false,
                msg = "节点名长度应为1~20位."
            })
        end

        -- ip
        local ip_len = slen(ip)
        if ip_len < 7 and ip_len > 15 then
            return res:json({
                success = false,
                msg = "IP 长度应为 7-15 位."
            })
        end

        -- port
        local port = tonumber(req.body.port)
        if port < 1 or port > 65535 then
            return json:json({
                success = false,
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
                        nodes = get_nodes()
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

        local id = req.body.id
        local name = req.body.name
        local ip = req.body.ip
        local port = tonumber(req.body.port)
        local api_username = req.body.api_username
        local api_password = req.body.api_password

        -- id
        if not id then
            return res:json({
                success = false,
                msg = "节点id不能为空"
            })
        end

        if not name or not ip or name == "" or ip == "" or port == "" then
            return res:json({
                success = false,
                msg = "节点名、IP、端口不得为空."
            })
        end

        -- name
        local name_len = slen(name)
        if name_len < 1 or name_len > 20 then
            return res:json({
                success = false,
                msg = "节点名长度应为1~20位."
            })
        end

        -- ip
        local ip_len = slen(ip)
        if ip_len < 7 and ip_len > 15 then
            return res:json({
                success = false,
                msg = "IP 长度应为 7-15 位."
            })
        end

        -- port
        if port < 1 or port > 65535 then
            return json:json({
                success = false,
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
                    nodes = get_nodes()
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
                    nodes = get_nodes()
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

        local nodes = get_nodes()
        local results = {}

        if nodes then
            results = sync_nodes(nodes, config.plugins)
        end

        return res:json({
            success = true,
            msg = "同步已提交, 请查看同步状态",
            data = {
                nodes = results,
            }
        })
    end)

    return node_router
end
