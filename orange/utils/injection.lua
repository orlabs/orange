---
-- origin code from
-- - https://github.com/bungle/lua-resty-injection/blob/master/lib/resty/injection.lua
-- - https://github.com/p0pr0ck5/lua-ffi-libinjection/blob/master/lib/resty/libinjection.lua
-- modified by xiaowu

local _M = {}
_M.version = "0.1.1"

local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_cdef = ffi.cdef

ffi_cdef[[
const char* libinjection_version(void);
int libinjection_sqli(const char* s, size_t slen, char fingerprint[]);
int libinjection_xss(const char* s, size_t slen);
]]

local fpr = ffi_new("char[?]", 8)

local lib, loaded

-- "borrowed" from CF aho-corasick lib
local function _loadlib()
    if (not loaded) then
        local path, so_path
        local libname = "libinjection.so"
        for k, v in string.gmatch(package.cpath, "[^;]+") do
            so_path = string.match(k, "(.*/)")
            if so_path then
                -- "so_path" could be nil. e.g, the dir path component is "."
                so_path = so_path .. libname

                -- Don't get me wrong, the only way to know if a file exist is
                -- trying to open it.
                local f = io.open(so_path)
                if f ~= nil then
                    io.close(f)
                    path = so_path
                    break
                end
            end
        end

        lib = ffi.load(path)
        if (lib) then
            loaded = true
        end
    end
end

function _M.sql(str)
    if type(str) ~= "string" or str == "" then
        return false
    end
    if (not loaded) then
        _loadlib()
    end
    if lib.libinjection_sqli(str, #str, fpr) ~= 0 then
        local fingerprint  = ffi_str(fpr)
        if not fingerprint then
            ngx.log(ngx.ERR, "==[sql] [injection: ", fingerprint, "]")
        end
        return true
    end
    return false
end

function _M.xss(str)
    if type(str) ~= "string" or str == "" then
        return false
    end
    if (not loaded) then
        _loadlib()
    end
    return lib.libinjection_xss(str, #str) ~= 0
end

return _M
