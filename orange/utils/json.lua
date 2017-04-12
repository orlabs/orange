local cjson = require("cjson.safe")
local ljson_decoder = require("orange.lib.json_decoder")

local _M = {
    json_decoder = ljson_decoder.new()
}


function _M.encode(data, empty_table_as_object)
    if not data then return nil end

    if cjson.encode_empty_table_as_object then
        -- empty table default is arrya
        cjson.encode_empty_table_as_object(empty_table_as_object or false)
    end

    if require("ffi").os ~= "Windows" then
        cjson.encode_sparse_array(true)
    end

    return cjson.encode(data)
end


function _M.decode(data)
    if not data then return nil end

    if not _M.json_decoder then
        return cjson.decode(data)
    end

    return _M.json_decoder:decode(data)
end


return _M
