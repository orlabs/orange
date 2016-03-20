local string_gsub = string.gsub
local string_find = string.find
local table_insert = table.insert

local _M = {}

function _M.trim_all(str)
    if not str or str == "" then return "" end
    local result = string_gsub(str, " ", "")
    return result
end

function _M.strip(str)
    if not str or str == "" then return "" end
    local result = string_gsub(str, "^ *", "")
    result = string_gsub(result, "( *)$", "")
    return result
end


function _M.split(str, delimiter)
    if not str or str == "" then return {} end
    if not delimiter or delimiter == "" then return { str } end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table_insert(result, match)
    end
    return result
end

function _M.startswith(str, substr)
    if str == nil or substr == nil then
        return false
    end
    if string_find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

function _M.endswith(str, substr)
    if str == nil or substr == nil then
        return false
    end
    local str_reverse = string.reverse(str)
    local substr_reverse = string.reverse(substr)
    if string.find(str_reverse, substr_reverse) ~= 1 then
        return false
    else
        return true
    end
end


--
--local a = _M.strip(" abc a    ")
--print(string.len(a))
--print(a)
--
--local b = table.concat(_M.split("a*bXc", "X"), "|")
--print(string.len(b))
--print(b)
