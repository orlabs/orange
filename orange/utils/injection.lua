---
-- origin code from
-- - https://github.com/bungle/lua-resty-injection/blob/master/lib/resty/injection.lua
-- - https://github.com/p0pr0ck5/lua-ffi-libinjection/blob/master/lib/resty/libinjection.lua
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

local load_path = "/opt/orange/deps/lib64/lua/5.1/libinjection.so"

local fpr = ffi_new("char[?]", 8)

local injection = { version = ffi_str(lib.libinjection_version()) }

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
            return true
        else
            return false
        end
    else
        return true
    end
end

function injection.sql(str)
    if (not loaded) then
        if (not _loadlib()) then
            return false
        end
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

function injection.xss(str)
    if (not loaded) then
        if (not _loadlib()) then
            return false
        end
    end
    local res, err = lib.libinjection_xss(str, #str) ~= 0
    if not err then
        ngx.log(ngx.ERR, "==[xss] [injection: ", err, "]")
    end
    return res
end

return injection
