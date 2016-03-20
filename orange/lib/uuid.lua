--
-- https://github.com/bungle/lua-resty-uuid/blob/master/lib/resty/uuid.lua
-- commit 9d1dba708e58cea110216085614104b2ff7f45c
--

local ffi          = require "ffi"
local ffi_new      = ffi.new
local ffi_str      = ffi.string
local ffi_load     = ffi.load
local ffi_cdef     = ffi.cdef
local C            = ffi.C
local os           = ffi.os
local tonumber     = tonumber
local setmetatable = setmetatable

ffi_cdef[[
typedef unsigned char uuid_t[16];
typedef long time_t;
typedef struct timeval {
    time_t tv_sec;
    time_t tv_usec;
} timeval;
   void uuid_generate(uuid_t out);
   void uuid_generate_random(uuid_t out);
   void uuid_generate_time(uuid_t out);
    int uuid_generate_time_safe(uuid_t out);
    int uuid_parse(const char *in, uuid_t uu);
   void uuid_unparse(const uuid_t uu, char *out);
    int uuid_type(const uuid_t uu);
    int uuid_variant(const uuid_t uu);
 time_t uuid_time(const uuid_t uu, struct timeval *ret_tv);
]]

local lib = os == "OSX" and C or ffi_load "uuid"
local uid = ffi_new "uuid_t"
local tvl = ffi_new "timeval"
local buf = ffi_new("char[?]", 36)

local uuid = {}
local mt   = {}

local function unparse(id)
    lib.uuid_unparse(id, buf)
    return ffi_str(buf, 36)
end

local function parse(id)
    return lib.uuid_parse(id, uid) == 0 and uid or nil
end

function uuid.generate()
    lib.uuid_generate(uid)
    return unparse(uid)
end

function uuid.generate_random()
    lib.uuid_generate_random(uid)
    return unparse(uid)
end

function uuid.generate_time()
    lib.uuid_generate_time(uid)
    return unparse(uid)
end

function uuid.generate_time_safe()
    local safe = lib.uuid_generate_time_safe(uid) == 0
    return unparse(uid), safe
end

function uuid.type(id)
    local parsed = parse(id)
    return parsed and lib.uuid_type(parsed)
end

function uuid.variant(id)
    local parsed = parse(id)
    return parsed and lib.uuid_variant(parsed)
end

function uuid.time(id)
    local parsed = parse(id)
    if parsed then
        local secs = lib.uuid_time(parsed, tvl)
        return tonumber(secs), tonumber(tvl.tv_usec)
    end
end

function uuid.is_valid(id)
    return not not parse(id)
end

mt.__call = uuid.generate

return setmetatable(uuid, mt)