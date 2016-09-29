local ngx_handle = require("bin.utils.ngx_handle")
local start_cmd = require("bin.cmds.start")
local stop_cmd = require("bin.cmds.stop")
local logger = require("bin.utils.logger")


local _M = {}


_M.help = [[
Usage: orange restart [OPTIONS]

Restart Orange with configurations(prefix/orange_conf/ngx_conf).

Options:
 -p,--prefix  (optional string) override prefix directory
 -o,--orange_conf (optional string) orange configuration file
 -c,--ngx_conf (optional string) nginx configuration file
 -h,--help (optional string) show help tips

Examples:
 orange restart  #use `/usr/local/orange` as workspace with `/usr/local/orange/conf/orange.conf` & `/usr/local/orange/conf/nginx.conf`
 orange restart --prefix=/opt/orange  #use the `prefix` as workspace with ${prefix}/conf/orange.conf & ${prefix}/conf/nginx.conf
 orange restart --orange_conf=/opt/orange/conf/orange.conf --prefix=/opt/orange --ngx_conf=/opt/orange/conf/nginx.conf
 orange restart -h  #just show help tips
]]

function _M.execute(origin_args)
    logger:info("Stop orange...")
    pcall(stop_cmd.execute, origin_args)

    logger:info("Start orange...")
    start_cmd.execute(origin_args)
end


return _M
