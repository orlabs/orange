local cjson = require("cjson")
local IO = require("orange.utils.io")

local _M = {}

function _M.load(config_path)
    config_path = config_path or "/etc/orange/orange.conf"
    local config_contents = IO.read_file(config_path)

    if not config_contents then
        ngx.log(ngx.ERR, "No configuration file at: ", config_path)
        os.exit(1)
    end

    local config = cjson.decode(config_contents)
    return config, config_path
end

return _M
