local BaseAPI = require("orange.plugins.base_api")
local common_api = require("orange.plugins.common_api")

local api = BaseAPI:new("consul_balancer-api", 2)
local table_insert = table.insert
local json = require "cjson"

local stat = require("orange.plugins.consul_balancer.stat")
local orange_db = require("orange.store.orange_db")

local service = ngx.shared.consul_upstream

local function load_service(name)
    local selectors = orange_db.get_json("consul_balancer.selectors")
    for _, s in pairs(selectors) do
        if s.name == name then
            local services = service:get(s.id)
            --ngx.log(ngx.ERR, "----", services)
            return s.id, services and json.decode(services) or nil            
        end
    end

    ngx.log(ngx.ERR, "not found service:", name)
    return nil, nil
end

api:merge_apis(common_api("consul_balancer"))

api:get("/consul_balancer/stat", function(store)
    return function(req, res, next)
        local max_count = req.query.max_count or 500
        local service_name = req.query.service

        local statistics = {}
        local sid, services = load_service(service_name)
        local count = 0
        if services and #services.upstreams > 0 then
            for _, upstream in pairs(services.upstreams) do
                local name = upstream["address"] .. ":" .. upstream["port"]
                local s = stat.get(sid .. "_" .. name)
                table_insert(statistics, {
                    name = name,
                    count = s.count
                })

                count = count + s.count
            end
        end

        local result = {
            success = true,
            data = {
            }   
        }

        if count > 0 then
            result.data.statistics = statistics
        end

        res:json(result)
    end
end)

api:get("/consul_balancer/clear", function(store)
    return function(req, res, next)
        stat.clear()
        local result = {
            success = true,
        }

        res:json(result)
    end
end)

api:get("/consul_balancer/debug", function(store)
    return function(req, res, next)
        local x = req.query.x
        local rules = nil
        if not x then
            local dict = req.query.dict
            if not dict then
                local stats = req.query.stats
                if not stats then
                    local selector_id = req.query.selector_id
                    rules = orange_db.get_json("consul_balancer.selector." .. selector_id .. ".rules") or {}
                else
                    rules = stat.get_all(500)
                end
            else
                rules = service.get(dict) or {}
            end
        else
            rules = orange_db.get_json(x) or {}
        end

        res:json({
            success = true,
            data = {
                rules = rules
            }
        })
    end
end)
return api
