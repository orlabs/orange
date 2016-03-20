local ipairs = ipairs
local tonumber = tonumber
local Store = require("orange.store.base")
local MySQLStore = Store:extend()


function MySQLStore:new(name)
    self._name = name
end

function MySQLStore:set(k, v)
    if not k or k == "" then return false, "nil key." end
    ngx.log(ngx.DEBUG, " mysql_store \"" .. self._name .. "\" get:" .. k)
end


function MySQLStore:get(k)
    if not k or k == "" then return nil end

    ngx.log(ngx.DEBUG, " mysql_store \"" .. self._name .. "\" set:" .. k, " v:", v)
end




return MySQLStore