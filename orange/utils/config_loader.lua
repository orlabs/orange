local type = type
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local table_concat = table.concat
local string_format = string.format
local cjson = require("cjson")
local IO = require("orange.utils.io")
local utils = require("orange.utils.utils")
local logger = require("orange.utils.logger")
local stringy = require("orange.utils.stringy")


local function get_type(value, val_type)
    if val_type == "array" and utils.is_array(value) then
        return "array"
    else
        return type(value)
    end
end

local function is_valid_IPv4(ip)
    if not ip or stringy.strip(ip) == "" then return false end

    local a, b, c, d = ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
    a = tonumber(a)
    b = tonumber(b)
    c = tonumber(c)
    d = tonumber(d)
    if not a or not b or not c or not d then return false end
    if a < 0 or 255 < a then return false end
    if b < 0 or 255 < b then return false end
    if c < 0 or 255 < c then return false end
    if d < 0 or 255 < d then return false end

    return true
end

local function is_valid_address(value, only_IPv4)
    if not value or stringy.strip(value) == "" then return false end

    local parts = stringy.split(value, ":")
    if #parts ~= 2 then return false end
    if stringy.strip(parts[1]) == "" then return false end
    if only_IPv4 and not is_valid_IPv4(parts[1]) then return false end
    local port = tonumber(parts[2])
    if not port then return false end
    if not (port > 0 and port <= 65535) then return false end

    return true
end




local _M = {}

function _M.load(config_path)
    config_path = config_path or "/etc/orange/orange.conf"
    local config_contents = IO.read_file(config_path)

    if not config_contents then
        ngx.log(ngx.ERR, "No configuration file at: ", config_path)
        os.exit(1)
    end
    ngx.log(ngx.ERR, "Load config file from ", config_path)

    local config = cjson.decode(config_contents)
    return config, config_path
end

return _M
