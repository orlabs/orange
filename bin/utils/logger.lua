local ansicolors = require("bin.lib.ansicolors")

local colors = {}

for _, v in ipairs({"red", "green", "yellow", "blue"}) do
    colors[v] = function(str) return ansicolors("%{"..v.."}"..str.."%{reset}") end
end


local Logger = {}

Logger.colors = colors

function Logger:set_silent(silent)
    self._silent = silent
end

function Logger:print(str)
    if not self._silent then
        print(str)
    end
end

function Logger:info(format, ...)
    local v = {...}
    if format and next(v) then
       self:print(colors.blue("[INFO] ").. string.format(format, ...))
   else
       self:print(colors.blue("[INFO] ").. (format or ""))
   end
end

function Logger:success(format, ...)
    local v = {...}
    if format and next(v) then
       self:print(colors.green("[SUCCESS] ").. string.format(format, ...))
    else
       self:print(colors.green("[SUCCESS] ").. (format or ""))
    end
end

function Logger:warn(format, ...)
    local v = {...}
    if format and next(v) then
       self:print(colors.yellow("[WARN] ").. string.format(format, ...))
    else
       self:print(colors.yellow("[WARN] ").. (format or ""))
    end
end

function Logger:error(format, ...)
    local v = {...}
    if format and next(v) then
       self:print(colors.red("[ERROR] ").. string.format(format, ...))
    else
       self:print(colors.red("[ERROR] ").. (format or ""))
    end
end

return Logger
