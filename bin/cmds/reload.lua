local ngx_handle = require("bin.utils.ngx_handle")
local args_util = require("bin.utils.args_util")
local logger = require("bin.utils.logger")


local _M = {}


_M.help = [[
Usage: orange reload [OPTIONS]

Reload Orange with configurations(prefix/orange_conf/ngx_conf).

Options:
 -p,--prefix  (optional string) override prefix directory
 -o,--orange_conf (optional string) orange configuration file
 -c,--ngx_conf (optional string) nginx configuration file
 -h,--help (optional string) show help tips

Examples:
 orange reload  #use `/usr/local/orange` as workspace with `/usr/local/orange/conf/orange.conf` & `/usr/local/orange/conf/nginx.conf`
 orange reload --prefix=/opt/orange  #use the `prefix` as workspace with ${prefix}/conf/orange.conf & ${prefix}/conf/nginx.conf
 orange reload --orange_conf=/opt/orange/conf/orange.conf --prefix=/opt/orange --ngx_conf=/opt/orange/conf/nginx.conf
 orange reload -h  #just show help tips
]]

function _M.execute(origin_args)

    -- format and parse args
    local args = {
        orange_conf = origin_args.orange_conf,
        prefix = origin_args.prefix,
        ngx_conf = origin_args.ngx_conf
    }
    for i, v in pairs(origin_args) do
        if i == "o" and not args.orange_conf then args.orange_conf = v end
        if i == "p" and not args.prefix then args.prefix = v end
        if i == "c" and not args.ngx_conf then args.ngx_conf = v end
    end

    -- use default args if not exist
    -- if not args.prefix then args.prefix = command_util.pwd() end
    if not args.prefix then args.prefix = "/usr/local/orange" end
    if not args.orange_conf then args.orange_conf = args.prefix .. "/conf/orange.conf" end
    if not args.ngx_conf then args.ngx_conf = args.prefix .. "/conf/nginx.conf" end

    if args then
        logger:info("args:")
        for i, v in pairs(args) do
            logger:info("\t%s:%s", i, v)
        end
        logger:info("args end.")
    end

    local err
    xpcall(function()
        local handler = ngx_handle:new(args)

        local result = handler:reload()
        if result == 0 then
            logger:success("Orange reloaded.")
        end
    end, function(e)
        logger:error("Could not reload Orange, error: %s", e)
        err = e
    end)

    if err then
        error(err)
    end
end


return _M
