local mysql = require("resty.mysql")
local cjson = require("cjson")
local logger = require("bin.utils.logger")

local _M = {}


function _M:new(conf)
    local instance = {}
    instance.conf = conf
    setmetatable(instance, { __index = self})
    return instance
end

function _M:exec(sql)
    local conf = self.conf
    local db, err = mysql:new()
    if not db then
        logger:error("Failed to instantiate mysql: %s", err)
        return
    end
    db:set_timeout(conf.timeout) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(conf.connect_config)
    if not ok then
        logger:error("Failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end

    --db:query("SET NAMES utf8")
    local res, err, errno, sqlstate = db:query(sql)

    if not res then
        logger:error("Bad result, err:%s errno:%s sqlstate:%s ", err, errno, sqlstate)
    end

    local ok, err = db:close()
    if not ok then
        logger:error("Failed to close db: %s", err)
        return
    end

    return res, err, errno, sqlstate
end


return _M
