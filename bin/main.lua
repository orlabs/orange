local version = require("orange.version")
local args_util = require("bin.utils.args_util")
local logger = require("bin.utils.logger")
local command_util = require("bin.utils.command_util")

local cmds = {
    start = "Start the Orange Gateway",
    stop = "Stop current Orange",
    restart = "Restart Orange",
    reload = "Reload the config of Orange",
    store = "Init/Update/Backup Orange store",
    version = "Show the version of Orange",
    register = "Register the node",
    help = "Show help tips"
}

local help_cmds = ""
for k, v in pairs(cmds) do
    help_cmds = help_cmds .. "\n" .. k .. "\t" .. v
end

local help = string.format([[
Orange v%s, OpenResty/Nginx API Gateway.

Usage: orange COMMAND [OPTIONS]

The commands are:
 %s
]], version, help_cmds)


local function exec(args, env)
    local cmd = table.remove(args, 1)
    if cmd == "help" or cmd == "-h" or cmd == "--help" then
        return logger:print(help)
    end

    if cmd == "version" or cmd == "-v" or cmd == "--version" then
        return logger:print(version)
    end

    if not cmd then
        logger:error("Error Usages. Please check the following tips.\n")
        logger:print(help)
        return
    elseif not cmds[cmd] then
        logger:error("No such command: %s. Please check the following tips.\n", cmd)
        logger:print(help)
        return
    end

    local command = require("bin.cmds." .. cmd)
    local cmd_exec = command.execute
    local cmd_help = command.help

    args = args_util.parse_args(args)
    if args.h or args.help then return logger:print(cmd_help) end

    logger:info("Orange: %s", version)
    logger:info("ngx_lua: %s", ngx.config.ngx_lua_version)
    logger:info("nginx: %s", ngx.config.nginx_version)
    if jit and jit.version then
        logger:info("Lua: %s", jit.version)
    end

    if env == 'prod' then
        args.prefix = "/usr/local/orange"
    else
        args.prefix = command_util.pwd()
    end

    xpcall(function() cmd_exec(args) end, function(err)
        local trace = debug.traceback(err, 2)
        logger:error("Error:")
        io.stderr:write(trace.."\n")
        os.exit(1)
    end)
end

return exec
