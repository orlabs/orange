local logger = require("bin.utils.logger")
local http = require("resty.http")
local io = require("orange.utils.io")
local json = require("orange.utils.json")

local _M = {}


_M.help = [[
Usage: orange register

Register current node to cluster

Examples:
 orange register
]]


local function base64_encode(source_str)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local s64 = ''
    local str = source_str

    while #str > 0 do
        local bytes_num = 0
        local buf = 0

        for byte_cnt = 1, 3 do
            buf = (buf * 256)
            if #str > 0 then
                buf = buf + string.byte(str, 1, 1)
                str = string.sub(str, 2)
                bytes_num = bytes_num + 1
            end
        end

        for group_cnt = 1, (bytes_num + 1) do
            local b64char = math.fmod(math.floor(buf / 262144), 64) + 1
            s64 = s64 .. string.sub(b64chars, b64char, b64char)
            buf = buf * 64
        end

        for fill_cnt = 1, (3 - bytes_num) do
            s64 = s64 .. '='
        end
    end

    return s64
end

function _M.execute(origin_args)

    local err

    -- format and parse args
    local args = {
        orange_conf = origin_args.orange_conf,
        prefix = origin_args.prefix
    }
    for i, v in pairs(origin_args) do
        if i == "o" and not args.orange_conf then args.orange_conf = v end
        if i == "p" and not args.prefix then args.prefix = v end
    end

    -- use default args if not exist
    -- if not args.prefix then args.prefix = command_util.pwd() end
    if not args.prefix then args.prefix = "/usr/local/orange" end
    if not args.orange_conf then args.orange_conf = args.prefix .. "/conf/orange.conf" end

    if args then
        logger:info("args:")
        for i, v in pairs(args) do
            logger:info("\t%s:%s", i, v)
        end
        logger:info("args end.")
    end

    xpcall(function()

        -- 读取 orange 配置文件
        local orange_conf_text = io.read_file(args.orange_conf)
        local orange_conf = json.decode(orange_conf_text)

        if #orange_conf.api.credentials[1] ~= 0 then
            logger:error("not configure api username and password")
            return
        end

        local credential = orange_conf.api.credentials[1]

        local httpc = http.new()

        -- 设置超时时间 200 ms
        httpc:set_timeout(200)

        local url = "http://127.0.0.1:7777"
        local authorization = base64_encode(string.format("%s:%s", credential.username, credential.password))
        local path = '/node/register'

        local resp, err = httpc:request_uri(url, {
            method = "POST",
            path = path,
            headers = {
                ["Authorization"] = authorization
            }
        })

        httpc:close()

        if not err then
            if resp.status == 200 then
                logger:success("Orange register to cluster.")
            else
                logger:error(resp.body)
            end
        else
            logger:error(err)
        end

    end, function(e)
        logger:error("Could not register Orange, error: %s", e)
        err = e
    end)

    if err then
        error(err)
    end
end


return _M
