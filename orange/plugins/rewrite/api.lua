local file_store = require("orange.store.file_store")

local API = {}


API["/rewrite/configs"] = {
    GET = function(store)
        return function(req, res, next)
            local result = {
                success = true,
                data = store:get_rewrite_config()
            }

            res:json(result)
        end
    end
}


return API