local lor = require("lor.index")

return function(config, store)

    local persist_router = lor:Router()
    local persist_model = require("dashboard.model.persist")(config)

    persist_router:get("/persist", function(req, res, next)
        res:render("persist-stat", {
            id = req.query.id,
            ip = req.query.ip
        })
    end)

    persist_router:get("/persist/statistic", function(req, res, next)

        local node_ip = req.query.ip or ''
        local limit = tonumber(req.query.minutes) or 720
        local group_by_day = false

        if limit > 2400 then
            group_by_day = true
        end

        if node_ip == '' then
            data = persist_model:get_stat(limit, group_by_day)
        else
            data = persist_model:get_stat_by_ip(node_ip, limit, group_by_day)
        end

        res:json({
            success = true,
            data = data
        })
    end)

    return persist_router
end
