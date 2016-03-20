local Object = require "orange.lib.classic"
local Store = Object:extend()

function Store:new(name)
    self._name = name
end

function Store:set(k, v)
    if not k or k == "" then return false, "nil key." end
    ngx.log(ngx.DEBUG, " store \"" .. self._name .. "\" get:" .. k)
end


function Store:get(k)
    if not k or k == "" then return nil end

    ngx.log(ngx.DEBUG, " store \"" .. self._name .. "\" set:" .. k, " v:", v)
end



return Store
