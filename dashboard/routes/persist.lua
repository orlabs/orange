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
        local limit = req.query.limit or 120

        if node_ip == '' then
            data = persist_model:get_stat(limit)
        else
            data = persist_model:get_stat_by_ip(node_ip, limit)
        end

        res:json({
            success = true,
            data = data
        })

    end)

    return persist_router
end
