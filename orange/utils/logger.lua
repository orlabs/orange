--- 
-- from https://github.com/Mashape/kong/blob/master/kong/cli/utils/logger.lua
-- modified by sumory.wu

-- logger util
local ansicolors = require "orange.lib.ansicolors"
local Object = require "orange.lib.classic"

--
-- Colors
--
local colors = {}
for _, v in ipairs({"red", "green", "yellow", "blue"}) do
    colors[v] = function(str) return ansicolors("%{"..v.."}"..str.."%{reset}") end
end

--
-- Logging
--
local Logger = Object:extend()

Logger.colors = colors

function Logger:set_silent(silent)
    self._silent = silent
end

function Logger:print(str)
    if not self._silent then
        print(str)
    end
end

function Logger:info(str)
    self:print(colors.blue("[INFO] ").. (str or "nil value"))
end

function Logger:success(str)
    self:print(colors.green("[OK] ").. (str or "nil value"))
end

function Logger:warn(str)
    self:print(colors.yellow("[WARN] ").. (str or "nil value"))
end

function Logger:error(str)
    self:print(colors.red("[ERR] ").. (str or "nil value"))
end

return Logger()
