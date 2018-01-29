local ipairs = ipairs
local table_insert = table.insert
local stat = ngx.shared.consul_upstream_stat


local _M = {}

function _M.get_one(key)
    local value, flags = stat:get(key)
    local count = value or 0
    return count
end

function _M.count(key, value)
    if not key then
        return
    end

    local newval, err = stat:incr(key, value)
    if not newval or err then
        stat:set(key, 1)
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
    local keys = stat:get_keys(max_count or 500)
    local result = {}

    if keys then
        for i, k in ipairs(keys) do
            table_insert(result, {
                rule_id = k,
                count = _M.get_one(k),
            })
        end
    end

    return result
end

function _M.clear()
    stat:flush_all()
    stat:flush_expired()
end

return _M
