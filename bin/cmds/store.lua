local logger = require("bin.utils.logger")
local args_util = require("bin.utils.args_util")
local db_util = require("bin.utils.db_util")
local command_util = require("bin.utils.command_util")

local _M = {}


_M.help = [[
Usage: orange store [OPTIONS]

Init/Update/Backup Orange store.

Options:
 -t,--type store type, only support `mysql` now.
 -d,--db database name, e.g. `orange`
 -hh,--host database host, e.g. `127.0.0.1`
 -pp,--port database port, e.g. `3306`
 -u,--user username for store
 -p,--pwd password for store
 -o,--operation action to perform(init/update/backup), only support `init` now.
 -f,--file when -o=init, this flag indicates the SQL file to import

Examples:
 orange store -t=mysql -d=orange -u=admin -p=123456 -o=init -f=/usr/local/orange/install/orange-v0.5.0.sql

]]

function _M.execute(origin_args)
    logger:info("Orange store operation start:")

    -- format and parse args
    local args = {
        store_type = origin_args.type,
        db = origin_args.db,
        host = origin_args.host,
        port = origin_args.port,
        user = origin_args.user,
        pwd = origin_args.pwd,
        operation = origin_args.operation,
        file = origin_args.file
    }
    for i, v in pairs(origin_args) do
        if i == "t" and not args.store_type then args.store_type = v end
        if i == "d" and not args.db then args.db = v end
        if i == "hh" and not args.host then args.host = v end
        if i == "pp" and not args.port then args.port = v end
        if i == "u" and not args.user then args.user = v end
        if i == "p" and not args.pwd then args.pwd = v end
        if i == "o" and not args.operation then args.operation = v end
        if i == "f" and not args.file then args.file = v end
    end

    if not args.store_type then args.store_type = "mysql" end

    if args.operation ~= "init" then
        return logger:error("%s is not supported yet.", args.operation)
    end

    if args.operation == "init" and not args.file then
        return logger:error("file is not given for `init`")
    end

    if not args.db then args.db = "orange" end
    if not args.host then args.host = "127.0.0.1" end
    if not args.port then args.port = "3306" end

    if args then
        logger:info("args:")
        for i, v in pairs(args) do
            logger:info("\t%s:%s", i, v)
        end
        logger:info("args end.")
    end
    
    local store_mysql = {
        timeout = 20000,
        connect_config = {
            host = args.host,
            port = args.port,
            database = args.db,
            user = args.user,
            password = args.pwd,
            max_packet_size = 1048576
        }
    }
    
    local db = db_util:new(store_mysql)
    local sql = command_util.read_file(args.file)
    db:exec(sql)

    logger:info("Store %s finished.", args.operation)
end


return _M
