local router = require("api.router")

function start_api_server(config, store)
    local lor = require("lor.index")
    local app = lor()

    -- routes
    app:use(router(config, store)())

    -- 404 error
    app:use(function(req, res, next)
        if req:is_found() ~= true then
            res:status(404):json({
                success = false,
                msg = "404! sorry, not found."
            })
        end
    end)

    -- error handle middleware
    app:erroruse(function(err, req, res, next)
        ngx.log(ngx.ERR, err)
        res:status(500):json({
            success = false,
            msg = "500! unknown error."
        })
    end)

    app:run()
end


return start_api_server