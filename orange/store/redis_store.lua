local ipairs = ipairs
local tonumber = tonumber
local Store = require("orange.store.base")
local RedisStore = Store:extend()


function RedisStore:new(options)
    options = options or {}
    RedisStore.super.new(self, "redis-store")
    self.store_type = "redis"
end

function RedisStore:set(k, v)
    if not k or k == "" then return false, "nil key." end
    ngx.log(ngx.DEBUG, " redis_store \"" .. self._name .. "\" set:" .. k, " v:", v)
end


function RedisStore:get(k)
    if not k or k == "" then return nil end
    ngx.log(ngx.DEBUG, " redis_store \"" .. self._name .. "\" get:" .. k)

end




return RedisStore