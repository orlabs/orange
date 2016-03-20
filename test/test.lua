local params = { true, false, true }
local expression = "( v[1] and v[2]) or v[3]"
local condition = string.gsub(expression, "(v%[[0-9]+%])", function(m)
    local tmp = string.gsub(m, "v%[([0-9]+)%]", function(n)
        n = tonumber(n)
        return tostring(params[n])
    end)
    return tmp
end)
print(condition)

condition = condition .. " efds"
local allowed_str = { "true", "false", "not", "and", "or", "%(", "%)", " " }
for i, v in ipairs(allowed_str) do
    condition = string.gsub(condition, v, "")
end


print(condition == "", string.len(condition))
print(condition, count)
