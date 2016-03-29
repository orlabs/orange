local pairs = pairs
local table_insert = table.insert
local string_match = string.match
local string_find = string.find
local string_format = string.format
local string_sub = string.sub
local string_gsub = string.gsub
local string_len = string.len
local ipairs = ipairs
local unpack = unpack
local type = type

local judge = require("orange.utils.judge")
local utils = require("orange.utils.utils")
local stringy = require("orange.utils.stringy")
local BasePlugin = require("orange.plugins.base")
local cjson = require("cjson")

local DivideHandler = BasePlugin:extend()
DivideHandler.PRIORITY = 2000


-- Replace `/request_path` with `request_path`, and then prefix with a `/`
-- or replace `/request_path/foo` with `/foo`, and then do not prefix with `/`.
local function strip_request_path(uri, strip_request_path_pattern)
    local uri = string_gsub(uri, strip_request_path_pattern, "", 1)

    if string_sub(uri, 0, 1) ~= "/" then
        uri = "/"..uri
    end
    return uri
end

local function ensure_end(uri)
    if not stringy.endswith(uri, "/") then
        uri = uri.."/"
    end
    return uri
end


function DivideHandler:new(store)
    DivideHandler.super.new(self, "Divide-plugin")
    self.store = store
end

function DivideHandler:access(conf)
    DivideHandler.super.access(self)
    local divide_config = self.store:get("divide_config")

    if divide_config.enable ~= true then
        return
    end

    local divide_rules = divide_config.divide_rules
    local ngx_var = ngx.var
    local uri = ngx_var.uri
    for i, rule in pairs(divide_rules) do
        local enable = rule.enable
        if enable == true then
            local matcher = rule.matcher
            local match_type = matcher.type
            local conditions = matcher.conditions
            local uri_condition = ""
            for m, n in ipairs(matcher.conditions) do
                if n.type == "URI" then
                    uri_condition = n.value
                end
            end


            local pass = false
            ngx.log(ngx.ERR, "match_type:", match_type)

            if match_type == 0 or match_type == 1 then
                pass = judge.filter_and_conditions(conditions)
            elseif match_type == 2 then
                pass = judge.filter_or_conditions(conditions)
            elseif match_type == 3 then
                pass = judge.filter_complicated_conditions(matcher.expression, conditions, self:get_name())
            end

            if pass then
                if rule.log == true then
                    ngx.log(ngx.ERR, "[Divide-Match-Rule] ", rule.name, " host:", ngx.var.host, " uri:", ngx.var.uri)
                end

                if rule.upstream_host and rule.upstream_url then
                    -- Append any querystring parameters modified during plugins execution
                    local qs = ""

                    if ngx_var.args ~= nil then
                        qs = "?"..ngx_var.args
                    end


                    ngx.var.upstream_host = rule.upstream_host
                    -- 外部upstream
                    -- ngx.var.upstream_url = rule.upstream_url .. strip_request_path(uri, uri_condition) .. qs
                    -- 内部upstream
                    ngx.var.upstream_url = rule.upstream_url
                else
                    ngx.log(ngx.ERR, "[Divide-Match-Rule:error] no upstream host or url. ", rule.name, " host:", ngx.var.host, " uri:", ngx.var.uri)
                end
                return
            else
                if rule.log == true then
                    ngx.log(ngx.ERR, "[Divide-NotMatch-Rule] ", rule.name, " host:", ngx.var.host, " uri:", ngx.var.uri)
                end
            end
        end
    end
end

return DivideHandler