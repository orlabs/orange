local _M = {}


_M.operator = {
    ["equal"] = "=",
    ["not_equal"] = "!=",
    ["regex"] = "match",
    ["not_regex"] = "not_match",
    ["null"] = "!",
    ["not_null"] = "!!"
}


return _M