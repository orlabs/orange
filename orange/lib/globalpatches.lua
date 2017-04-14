---
-- Override global(_G) namepace, inspired by kong
--
return function(opts)
    -- For further setting
    opts = opts or {}

    -- Add a special randomseed for math, no arguments
    do
        local utils = require "orange.utils.utils"
        local randomseed = math.randomseed
        local seed

        _G.math.randomseed = function()
            if not seed then
                seed = utils.get_random_seed()
            else
                ngx.log(ngx.ERR, "The seed random number generator seed has already seeded with: " .. seed .. "\n")
            end
            randomseed(seed)
            return seed
        end
    end
end
