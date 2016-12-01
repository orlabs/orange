---
-- from https://github.com/Mashape/kong/blob/master/kong/plugins/base_plugin.lua
-- modified by sumory.wu

require "bit32"

local Object = require "orange.lib.classic"
local BasePlugin = Object:extend()

BasePlugin.TAGS = {
    REDIRECT        = 0x00000001
    REWRITE         = 0x00000002
    ACCESS          = 0x00000004
    HEADER_FILTER   = 0x00000008
    BODAY_FILTER    = 0x00000010
}

function BasePlugin:new(name)
    self._name = name
end

function BasePlugin:get_tag()
    return bit32.bor(TAGS.REDIRECT,TAGS.REWRITE,TAGS.ACCESS,TAGS.HEADER_FILTER,TAGS.BODAY_FILTER)
end

function BasePlugin:init_worker()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": init_worker")
end

function BasePlugin:redirect()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": redirect")
end

function BasePlugin:rewrite()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": rewrite")
end

function BasePlugin:access()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": access")
end

function BasePlugin:header_filter()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": header_filter")
end

function BasePlugin:body_filter()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": body_filter")
end

function BasePlugin:log()
    ngx.log(ngx.DEBUG, " executing plugin \"", self._name, "\": log")
end

return BasePlugin
