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

local utils = require("orange.utils.utils")
local stringy = require("orange.utils.stringy")
local orange_db = require("orange.store.orange_db")
local judge_util = require("orange.utils.judge")
local extractor_util = require("orange.utils.extractor")
local handle_util = require("orange.utils.handle")
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
    
    local divide_config = {
        enable = orange_db.get("divide.enable"),
        rules = orange_db.get_json("divide.rules")
    }

    if not divide_config or divide_config.enable ~= true then
        return
    end

    local ngx_var = ngx.var

    local rules = divide_config.rules
    if not rules or type(rules) ~= "table" or #rules<=0 then
        return
    end
    
    for i, rule in ipairs(rules) do
        local enable = rule.enable
        if enable == true then

            -- judge阶段
            local judge = rule.judge
            local judge_type = judge.type
            local conditions = judge.conditions
            local pass = false
            if judge_type == 0 or judge_type == 1 then
                pass = judge_util.filter_and_conditions(conditions)
            elseif judge_type == 2 then
                pass = judge_util.filter_or_conditions(conditions)
            elseif judge_type == 3 then
                pass = judge_util.filter_complicated_conditions(judge.expression, conditions, self:get_name())
            end

            -- extract阶段
            local extractor = rule.extractor
            local extractor_type = extractor.type
            local extractions = extractor and extractor.extractions
            local variables
            if extractions then
                variables = extractor_util.extract(extractor_type, extractions)
            end

            -- handle阶段
            if pass then
                if rule.log == true then
                    ngx.log(ngx.INFO, "[Divide-Match-Rule] ", rule.name, " host:", ngx_var.host, " uri:", ngx_var.uri)
                end

                if rule.upstream_url then
                    if not rule.upstream_host or rule.upstream_host=="" then -- host默认取请求的host
                        ngx_var.upstream_host = ngx_var.host
                    else 
                        ngx_var.upstream_host = handle_util.build_upstream_host(extractor_type, rule.upstream_host, variables, self:get_name())
                    end

                    ngx_var.upstream_url = handle_util.build_upstream_url(extractor_type, rule.upstream_url, variables, self:get_name())
                    ngx.log(ngx.INFO, "[Divide-Match-Rule:upstream] ", rule.name, " extractor_type:", extractor_type,
                        " upstream_host:", ngx_var.upstream_host, " upstream_url:", ngx_var.upstream_url)
                else
                    ngx.log(ngx.INFO, "[Divide-Match-Rule:error] no upstream host or url. ", rule.name, " host:", ngx_var.host, " uri:", ngx_var.uri)
                end

                return
            else
                if rule.log == true then
                    ngx.log(ngx.INFO, "[Divide-NotMatch-Rule] ", rule.name, " host:", ngx_var.host, " uri:", ngx_var.uri)
                end
            end
        end
    end
end

return DivideHandler