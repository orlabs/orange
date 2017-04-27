--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/4/26
-- Time: 20:50
-- To change this template use File | Settings | File Templates.
--

local handle_util = require("orange.utils.handle")
local extractor_util = require("orange.utils.extractor")

local _M = {}

function _M:set_headers(rule)
    local extractor,headers= rule.extractor,rule.headers
    local variables = extractor_util.extract_variables(extractor)

    for _, v in pairs(headers) do

        if v.type == "normal" then
            ngx.req.set_header(v.name,v.value)
            ngx.log(ngx.INFO,'[plug header][normal] add headers [',v.name,":",v.value,']')
        elseif v.type == "extraction" then
            local value = handle_util.build_uri(extractor.type, v.value, variables)
            ngx.req.set_header(v.name,value)
            ngx.log(ngx.INFO,'[plug header][extraction] add headers [',v.name,":",value,']')
        end
    end
end

return _M