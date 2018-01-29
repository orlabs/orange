-- general utility functions.
-- some functions is from [kong](getkong.org)
local require = require
local uuid = require("orange.lib.jit-uuid")
local date = require("orange.lib.date")
local type = type
local pcall = pcall
local pairs = pairs
local tostring = tostring
local string_gsub = string.gsub
local string_find = string.find
local ffi = require "ffi"
local ffi_cdef = ffi.cdef
local ffi_typeof = ffi.typeof
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C

ffi_cdef[[
typedef unsigned char u_char;
int RAND_bytes(u_char *buf, int num);
]]

local _M = {}

function _M.now()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H:%M:%S")
    return result
end

function _M.current_timetable()
    local n = date()
    local yy, mm, dd = n:getdate()
    local h = n:gethours()
    local m = n:getminutes()
    local s = n:getseconds()
    local day = yy .. "-" .. mm .. "-" .. dd
    local hour = day .. " " .. h
    local minute = hour .. ":" .. m
    local second = minute .. ":" .. s

    return {
        Day = day,
        Hour = hour,
        Minute = minute,
        Second = second
    }
end

function _M.current_second()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H:%M:%S")
    return result
end

function _M.current_minute()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H:%M")
    return result
end

function _M.current_hour()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H")
    return result
end

function _M.current_day()
    local n = date()
    local result = n:fmt("%Y-%m-%d")
    return result
end

function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

--- Retrieves the hostname of the local machine
-- @return string  The hostname
function _M.get_hostname()
    local f = io.popen ("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()
    hostname = string_gsub(hostname, "\n$", "")
    return hostname
end

--- Generates a random unique string
-- @return string  The random string (a uuid without hyphens)
function _M.random_string()
    return uuid():gsub("-", "")
end

function _M.new_id()
    return uuid()
end

--- Calculates a table size.
-- All entries both in array and hash part.
-- @param t The table to use
-- @return number The size
function _M.table_size(t)
    local res = 0
    if t then
        for _ in pairs(t) do
            res = res + 1
        end
    end
    return res
end

--- Merges two table together.
-- A new table is created with a non-recursive copy of the provided tables
-- @param t1 The first table
-- @param t2 The second table
-- @return The (new) merged table
function _M.table_merge(t1, t2)
    local res = {}
    for k,v in pairs(t1) do res[k] = v end
    for k,v in pairs(t2) do res[k] = v end
    return res
end

--- Checks if a value exists in a table.
-- @param arr The table to use
-- @param val The value to check
-- @return Returns `true` if the table contains the value, `false` otherwise
function _M.table_contains(arr, val)
    if arr then
        for _, v in pairs(arr) do
            if v == val then
                return true
            end
        end
    end
    return false
end

--- Checks if a table is an array and not an associative array.
-- *** NOTE *** string-keys containing integers are considered valid array entries!
-- @param t The table to check
-- @return Returns `true` if the table is an array, `false` otherwise
function _M.is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil and t[tostring(i)] == nil then return false end
    end
    return true
end

--- Deep copies a table into a new table.
-- Tables used as keys are also deep copied, as are metatables
-- @param orig The table to copy
-- @return Returns a copy of the input table
function _M.deep_copy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_M.deep_copy(orig_key)] = _M.deep_copy(orig_value)
        end
        setmetatable(copy, _M.deep_copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Try to load a module.
-- Will not throw an error if the module was not found, but will throw an error if the
-- loading failed for another reason (eg: syntax error).
-- @param module_name Path of the module to load (ex: kong.plugins.keyauth.api).
-- @return success A boolean indicating wether the module was found.
-- @return module The retrieved module.
function _M.load_module_if_exists(module_name)
    local status, res = pcall(require, module_name)
    if status then
        return true, res
        -- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
    elseif type(res) == "string" and string_find(res, "module '"..module_name.."' not found", nil, true) then
        return false
    else
        error(res)
    end
end

--- checks the hostname type; ipv4, ipv6, or name.
-- Type is determined by exclusion, not by validation. So if it returns 'ipv6' then
-- it can only be an ipv6, but it is not necessarily a valid ipv6 address.
-- @param name the string to check (this may contain a portnumber)
-- @return string either; 'ipv4', 'ipv6', or 'name'
-- @usage hostname_type("123.123.123.123")  -->  "ipv4"
-- hostname_type("::1")              -->  "ipv6"
-- hostname_type("some::thing")      -->  "ipv6", but invalid...
function _M.hostname_type(name)
    local remainder, colons = string_gsub(name, ":", "")
    if colons > 1 then
        return "ipv6"
    end
    if remainder:match("^[%d%.]+$") then
        return "ipv4"
    end
    return "name"
end

---Try to generate a random seed using OpenSSL.
-- ffi based, would be more effenticy
-- This function is mainly ispired by https://github.com/bungle/lua-resty-random
-- @return a pseudo-random number for math.randomseed
do
    local bytes_buf_t = ffi_typeof "uint8_t[?]"
    local n_bytes = 4
    function _M.get_random_seed()
        local buf = ffi_new(bytes_buf_t, n_bytes)

        if C.RAND_bytes(buf, n_bytes) == 0 then
            ngx.log(ngx.ERR, "could not get random bytes, using ngx.time() + ngx.worker.pid() instead")
            return ngx.time() + ngx.worker.pid()
        end

        local a, b, c, d = ffi_str(buf, n_bytes):byte(1, 4)
        return a * 0x1000000 + b * 0x10000 + c * 0x100 + d
    end
end

return _M
