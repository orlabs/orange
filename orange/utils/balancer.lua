---
-- from https://github.com/Mashape/kong/blob/master/kong/core/balancer.lua
-- modified by zhjwpku@github

local orange_db = require "orange.store.orange_db"
local pl_tablex = require "pl.tablex"
local dns_client = require "resty.dns.client"
local ring_balancer = require "resty.dns.balancer"

local toip = dns_client.toip
local log = ngx.log

local ERROR = ngx.ERR
local DEBUG = ngx.DEBUG
local EMPTY_T = pl_tablex.readonly {}

--===========================================================
-- Ring-balancer based resolution
--===========================================================
local balancers = {}  -- table holding our balancer objects, indexed by upstream name

-- caching logic;
-- we retain 3 entities;
-- 1) list of upstreams: to be invalidated on any upstream change
-- 2) individual upstreams: to be invalidated on individual basis
-- 3) target history for an upstream, invalidated when:
--    a) along with the upstream it belongs to
--    b) upon any target change for the upstream (can only add entries)
-- Distinction between 1 and 2 makes it possible to invalidate indvidual
-- upstreams, instead of all at once forcing to rebuild all balancers

-- delect a balancer object from our internal cache
local function invalidate_balancer(upstream_name)
    balancers[upstream_name] = nil
end

-- finds and returns an upstream entity. This function covers
-- caching, invalidation, et al.
-- @return upstream table, or `false` if not found, or nil+error
local function get_upstream(upstream_name)
    -- selectors contains the upstreams
    local upstreams = orange_db.get_json("balancer.selectors")
    if not upstreams then
        return false  -- no upstreams cache
    end

    -- clear the balancers[upstream_name] that have been removed in orange_db
    local upstreams_dict = {}
    for _, upstream in pairs(upstreams) do
        if upstream and upstream.name then
            upstreams_dict[upstream.name] = upstream
        end
    end

    for k, _ in pairs(balancers) do
        if not upstreams_dict[k] then
            -- this one is not in orange_db, so clear the balancer object
            balancers[k] = nil
        end
    end

    local upstream_ret = upstreams_dict[upstream_name]
    if upstream_ret and upstream_ret.enable == true then
        return upstream_ret
    end

    return false -- no upstream by this name
end

-- applies the history of lb transactions from index `start` forward
-- @param rb ring-balancer object
-- @param history list of targets/transactions to be applied
-- @param start the index where to start in `history` parameter
-- @return true
local function apply_history(rb, history, start)
    for i = start, #history do
        local target = history[i]

        if target.weight > 0 then
            assert(rb:addHost(target.name, target.port, target.weight))
        else
            assert(rb:removeHost(target.name, target.port))
        end

        rb.__targets_history[i] = {
            name = target.name,
            port = target.port,
            weight = target.weight,
            order = target.order,
        }
    end

    return true
end

-- looks up a balancer for the target.
-- @param target the table with the target details
-- @return balancer if found, or `false` if not found, or nil+error on error
local get_balancer = function(target)
    -- NOTE: only called upon first lookup, so `cache_only` limitations do not apply here
    local hostname = target.host

    -- first go and find the upstream object, from orange_db
    local upstream = get_upstream(hostname)

    if upstream == false then
        return false    -- no upstream by this name
    end

    -- we've got the upstream, now fetch its targets, from orange_db

    local targets_history = orange_db.get_json("balancer.selector." .. upstream.id .. ".rules")

    if not targets_history then
        return false    -- TODO, for now, just simply reply false
    end

    -- perform some raw data updates
    for _, t in ipairs(targets_history) do
        -- split `target` field into `name` and `port`
        local port
        t.name, port = string.match(t.target, "^(.-):(%d+)$")
        t.port = tonumber(port)

        -- need exact order, so create sort-key by create-time and uuid
        t.order = t.time .. ":" .. t.id
    end

    table.sort(targets_history, function(a, b)
        return a.order < b.order
    end)

    local balancer = balancers[hostname]
    if not balancer then
        -- no balancer yet (or invalidated) so create a new one
        balancer, err = ring_balancer.new({
            wheelsize = upstream.slots,
            order = upstream.orderlist,
            dns = dns_client,
        })

        if not balancer then
            return balancer, err
        end

        -- NOTE: we're inserting a foreign entity in the balancer, to keep track of
        -- target-history changes
        balancer.__targets_history = {}
        balancers[upstream.name] = balancer
    end

    -- check history state
    -- NOTE: in the code below variables are similarly named, but the
    -- ones with `__`-prefixed, are the ones on the `balancer` object, and the
    -- regular ones are the ones we just fetched an are comparing against.
    local __size = #balancer.__targets_history
    local size = #targets_history

    if __size ~= size or
        (balancer.__targets_history[__size] or EMPTY_T).order ~=
        (targets_history[size] or EMPTY_T).order then
        -- last entries in history don't match, so we must do some updates.

        -- compare balancer history with db-loaded history
        local last_equal_index = 0  -- last index where history is the same
        for i, entry in ipairs(balancer.__targets_history) do
            if entry.order ~= (targets_history[i] or EMPTY_T).order then
                last_equal_index = i - 1
                break
            end
        end

        if last_equal_index == __size then
            -- history is the same, so we only need to add new entries
            apply_history(balancer, targets_history, last_equal_index + 1)
        else
            -- history not the same.
            -- TODO: ideally we would undo the last ones until we're equal again
            -- and can replay changes, but not supported by ring-balancer yet.
            -- for now, create a new balancer from scratch
            balancer, err = ring_balancer.new({
                wheelsize = upstream.slots,
                order = upstream.orderlist,
                dns = dns_client,
            })

            if not balancer then
                return balancer, err
            end

            balancer.__targets_history = {}
            balancers[upstream.name] = balancer
            apply_history(balancer, targets_history, 1)
        end
    end

    return balancer
end

--===========================================================
-- Main entry point when resolving
--===========================================================

-- Resolves the target structure in-place (field `ip`, port, and `hostname`).
--
-- If the hostname matches an 'upstream' pool, then it must be balanced in that
-- pool, in this case any port number provided will be ignored, as the pool provides it.
--
-- @param target the data structure as defined in `core.access.before` where it is created
-- return true one success, nil+error otherwise
local function execute(target)
    if target.type ~= "name" then
        -- it's an ip address (v4 or v6), so nothing we can do...
        target.ip = target.host
        target.port = target.port or 80
        target.hostname = target.host
        return true
    end

    -- when tries == 0 it runs before the `balancer` context (in the `access` context),
    -- when tries >= 2 then it performs a retry in the `balancer` context
    local dns_cache_only = target.try_count ~= 0
    local balancer

    if dns_cache_only then
        -- retry, so balancer is already set if there was one
        balancer = target.balancer

    else
        local err
        -- first try, so try and find a matching balancer/upstream object
        balancer, err = get_balancer(target)

        if err then -- check on err, `nil` without `err` means we do dns resolution
            return nil, err
        end

        -- store for retries
        target.balancer = balancer
    end

    if balancer then
        -- have to invoke the ring-balancer
        local hashValue = nil -- TODO: implement, nil does simple round-robin

        local ip, port, hostname = balancer:getPeer(hasValue, nil, dns_cache_only)

        ngx.log(ngx.ERR, "[ip]:", ip, " [port]: ", port)
        if not ip then
            if port == "No peers are available" then
                -- in this case a "503 service unavailable", others will be a 500.
                log(ERROR, "name resolution failed for '", tostring(target.host),
                             "': ", port)
                return ngx.exit(503)
            end

            return nil, port
        end

        target.ip = ip
        target.port = port
        target.hostname = hostname
        return true
    end

    -- have to do a regular DNS lookup
    local ip, port = toip(target.host, target.port, dns_cache_only)
    if not ip then
        if port == "dns server error; 3 name error" then
            -- in this case a "503 service unavailable", others will be a 500.
            log(ERROR, "name resolution failed for '", tostring(target.host),
                         "': ", port)
            return ngx.exit(503)
        end
        return nil, port
    end

    target.ip = ip
    target.port = port
    target.hostname = target.host

    return true
end

return {
    execute = execute,
    invalidate_balancer = invalidate_balancer,
}
