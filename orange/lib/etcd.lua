-- https://github.com/ledgetech/lua-resty-http
local http = require "resty.http"
local typeof = require "typeof"
local encode_args = ngx.encode_args
local setmetatable = setmetatable
local decode_json, encode_json
do
    local cjson = require "cjson.safe"
    decode_json = cjson.decode
    encode_json = cjson.encode
end
local clear_tab = require "table.clear"
--local tab_nkeys = require "table.nkeys"
local split = require "ngx.re" .split
local concat_tab = table.concat
local tostring = tostring
local select = select
local ipairs = ipairs
local type = type
local error = error
local ERR = ngx.ERR


local _M = {}
local mt = { __index = _M }
local ops = {}

local normalize
