local ipairs = ipairs
local tonumber = tonumber
local Store = require("orange.store.base")
local RedisStore = Store:extend()


function RedisStore:new(name)
    self._name = name
end

function RedisStore:set(k, v)
    if not k or k == "" then return false, "nil key." end
    ngx.log(ngx.DEBUG, " redis_store \"" .. self._name .. "\" get:" .. k)
end


function RedisStore:get(k)
    if not k or k == "" then return nil end

    ngx.log(ngx.DEBUG, " redis_store \"" .. self._name .. "\" set:" .. k, " v:", v)
end




return RedisStore