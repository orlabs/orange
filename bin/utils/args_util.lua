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


    if not args then return {} end

    local result = {}
    for k, v in gmatch(args, "(%w+)=(%w*)") do
        if not v then v = ""
        end
        result[k] = v
    end
    return result
end


return _M
