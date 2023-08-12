---
-- origin code from https://github.com/bungle/lua-resty-injection
-- modified by xiaowu

local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load

ffi_cdef[[
const char* libinjection_version(void);
int libinjection_sqli(const char* s, size_t slen, char fingerprint[]);
int libinjection_xss(const char* s, size_t slen);
]]

local lib = ffi_load("libinjection.so")
local fpr = ffi_new("char[?]", 8)

local injection = { version = ffi_str(lib.libinjection_version()) }

function injection.sql(str)
    if lib.libinjection_sqli(str, #str, fpr) ~= 0 then
        return true, ffi_str(fpr)
    end
    return false
end

function injection.xss(str)
    return lib.libinjection_xss(str, #str) ~= 0
end

return injection
