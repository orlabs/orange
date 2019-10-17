
local _M = {}

function _M.parse_args(args)
    if not args then
        args = _G.arg
    end


    if not args then return {} end

    local result = {}
    for k, v in gmatch(args.."&", "(.+)=(.-)&") do
        if not v then v = ""
        end
        result[k] = v
    end
    return result
end


return _M
