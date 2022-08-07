local pairs = pairs
local smatch = string.match
local slen = string.len
local http = require("resty.http")
local json = require("orange.utils.json")
local encode_base64 = ngx.encode_base64
local string_format = string.format
local lor = require("lor.index")
local socket = require("socket")
local orange_db = require("orange.store.orange_db")
local sputils = require("orange.utils.sputils")

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
    --local function get_ip_by_hostname(hostname)
    --    local ip, resolved = socket.dns.toip(hostname)
    --    local ListTab = {}
    --    for k, v in ipairs(resolved.ip) do
    --        table.insert(ListTab, v)
    --    end
    --    return unpack(ListTab)
    --end


    -- 节点同步
    local function sync_nodes(nodes, plugins)

        for _, node in pairs(nodes) do
            if node.ip and node.port and node.api_username and node.api_password then

                local httpc = http.new()

                -- 设置超时时间 1000 ms
                httpc:set_timeout(1000)

                -- 解析ip
                local nodeIp = sputils.hostToIp(node.ip)
                local url = string_format("http://%s:%s", nodeIp, node.port)
                local authorization = encode_base64(string_format("%s:%s", node.api_username, node.api_password))
                local path = '/node/sync?seed=' .. ngx.time()

                ngx.log(ngx.INFO, url .. path)

                local resp, err = httpc:request_uri(url, {
                    method = "POST",
                    path = path,
                    headers = {
                        ["Authorization"] = authorization
                    }
                })

                local sync_status = ''

                if not resp or err then
                    ngx.log(ngx.ERR, string_format("%s : %s", nodeIp, err))
                    sync_status = '{"ERROR":false}'
                else
                    ngx.log(ngx.ERR, resp.body)
                    local body = json.decode(resp.body)
                    sync_status = json.encode(body.data)
                end

                node_model:update_node_status(node.id, sync_status)

                httpc:close()
            end
        end

        return get_nodes()
    end

    function node_router:register()
        local local_ip = os.getenv("ORANGE_HOST")
        --local local_ip = get_ip_by_hostname(socket.dns.gethostname())
        node_model:registry(local_ip, 7777, config.api.credentials[1])
    end

    node_router:post("/node/register", function(req, res, next)

        node_router:register()

        res:json({
            success = true,
            data = {
                nodes = get_nodes()
            }
        })
    end)

    node_router:get("/node/manage", function(req, res, next)
        res:render("node")
    end)

    node_router:get("/node/persist", function(req,res,next)
        local enable =  orange_db.get("persist.enable")
        local id = req.query.id or ''
        local ip = req.query.ip or ''

        if enable then
            local url = string.format("/persist?id=%s&ip=%s", id, ip)
            res:redirect(url)
        else
            res:send("没有启用 persist 插件")
        end
    end)

    node_router:post("/node/remove_error_nodes", function(req, res, next)

        node_model:remove_error_nodes()

        res:json({
            success = true,
            data = {
                nodes = get_nodes()
            }
        })
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

        -- 取消ip验证
        --local ip_len = slen(ip)
        --if ip_len < 7 and ip_len > 15 then
        --    return res:json({
        --        success = false,
        --        msg = "IP 长度应为 7-15 位."
        --    })
        --end

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

        -- 取消ip验证
        --local ip_len = slen(ip)
        --if ip_len < 7 and ip_len > 15 then
        --    return res:json({
        --        success = false,
        --        msg = "IP 长度应为 7-15 位."
        --    })
        --end

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
