local ipairs = ipairs
local type = type
local tonumber = tonumber
local tostring = tostring
local loadstring = loadstring
local table_insert = table.insert
local string_gsub = string.gsub
local utils = require("orange.utils.utils")
local condition = require("orange.utils.condition")


local _M = {}

function _M.parse_conditions(expression, params)
    if not params or not utils.table_is_array(params) or #params == 0 then
        return false
    end

    local new_params = {}
    for i, v in ipairs(params) do
        if v == nil or type(v) ~= "boolean" then
            ngx.log(ngx.ERR, "condition value[", v, "] is nil or not a `boolean` value.")
            return false
        end
        table_insert(new_params, v)
    end

    local condition = string_gsub(expression, "(v%[[0-9]+%])", function(m)
        local tmp = string_gsub(m, "v%[([0-9]+)%]", function(n)
            n = tonumber(n)
            return tostring(new_params[n])
        end)
        return tmp
    end)

    if not condition or condition == "" then return false end

    local trip_allowed_str = condition
    local allowed_str = { "true", "false", "not", "and", "or", "%(", "%)", " " }
    for i, v in ipairs(allowed_str) do
        trip_allowed_str = string_gsub(trip_allowed_str, v, "")
    end
    if trip_allowed_str ~= "" then return false end

    if condition then
        return true, condition
    else
        return false
    end
end


function _M.filter_and_conditions(conditions)
    if not conditions then return false end

    local pass = false
    for i, c in ipairs(conditions) do
        pass = condition.judge(c)
        if not pass then
            return false
        end
    end

    return pass
end

function _M.filter_or_conditions(conditions)
    if not conditions then return false end

    local pass = false
    for i, c in ipairs(conditions) do
        pass = condition.judge(c)
        if pass then
            return true
        end
    end

    return pass
end

function _M.filter_complicated_conditions(expression, conditions, plugin_name)
    if not expression or expression == "" or not conditions then return false end

    local params = {}
    for i, c in ipairs(conditions) do
        table_insert(params, condition.judge(c))
    end

    local ok, condition = _M.parse_conditions(expression, params)
    if not ok then return false end

    local pass = false
    local func, err = loadstring("return " .. condition)
    if not func or err then
        ngx.log(ngx.ERR, "failed to load script: ", condition)
        return false
    end

    pass = func()
    if pass then
        ngx.log(ngx.INFO, "[", plugin_name or "", "]filter_complicated_conditions: ", expression)
    end

    return pass
end

function _M.judge_selector(selector, plugin_name)
    if not selector or not selector.judge then return false end

    local selector_judge = selector.judge
    local judge_type = selector_judge.type
    local conditions = selector_judge.conditions

    local selector_pass = false
    if judge_type == 0 or judge_type == 1 then
        selector_pass = _M.filter_and_conditions(conditions)
    elseif judge_type == 2 then
        selector_pass = _M.filter_or_conditions(conditions)
    elseif judge_type == 3 then
        selector_pass = _M.filter_complicated_conditions(selector_judge.expression, conditions, plugin_name)
    end

    return selector_pass
end

function _M.judge_rule(rule, plugin_name)
    if not rule or not rule.judge then return false end

    local judge = rule.judge
    local judge_type = judge.type
    local conditions = judge.conditions
    local pass = false
    if judge_type == 0 or judge_type == 1 then
        pass = _M.filter_and_conditions(conditions)
    elseif judge_type == 2 then
        pass = _M.filter_or_conditions(conditions)
    elseif judge_type == 3 then
        pass = _M.filter_complicated_conditions(judge.expression, conditions, plugin_name)
    end

    return pass
end


return _M
