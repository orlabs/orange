local _M = {}

local KEY_TRAFFIC_READ = "TRAFFIC_READ"
local KEY_TRAFFIC_WRITE = "TRAFFIC_WRITE"
local KEY_TOTAL_REQUEST_TIME = "TOTAL_REQUEST_TIME"

local KEY_REQUEST_2XX = "REQUEST_2XX"
local KEY_REQUEST_3XX = "REQUEST_3XX"
local KEY_REQUEST_4XX = "REQUEST_4XX"
local KEY_REQUEST_5XX = "REQUEST_5XX"


local _M = {}
local status = ngx.shared.url_monitor


function _M.get_one(key)
    local value, flags = status:get(key)
    local count = value or 0
    return count
end


function _M.count(key, value)
    if not key then
        return
    end

    local newval, err = status:incr(key, value)
    if not newval or err then
        status:set(key, 1)
    end
end

function _M.get(key)
    return {
        count = _M.get_one(key)
    }
end

---
-- be careful when calling this if the dict contains a huge number of keys
-- @param max_count only the first max_count keys (if any) are returned
--
function _M.get_all(max_count)
    local keys = status:get_keys(max_count or 500)
    local result = {}

    if keys then
        for i, k in ipairs(keys) do
            table_insert(result, {
                name = k,
                count = _M.get_one(k)
            })
        end
    end

    return result
end


return _M
