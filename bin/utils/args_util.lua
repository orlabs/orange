local function split(str, delimiter)
    if not str or str == "" then return {} end
    if not delimiter or delimiter == "" then return { str } end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end


local _M = {}

function _M.parse_args(args)
    if not args then 
        args = _G.arg
    end

    local result = {}
    local index = 1
    if args then
        while index <= #args do
            local item = args[index]
            local v = item:match('^-(.+)')
            local is_long
            if v then
                if v:find("^-") then
                    v = v:sub(2)
                end

                -- v: flag=abc
                local split_kv = split(v,'=')
                local k = split_kv[1] or v
                local v = split_kv[2] or true
                if v then
                    result[k] = v
                end
            end

            index = index + 1
        end
    end

    return result
end


return _M
