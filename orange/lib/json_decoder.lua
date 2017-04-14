-- Helper wrappring script for loading shared object libac.so (FFI interface)
-- from package.cpath instead of LD_LIBRARTY_PATH.
--

local ffi = require 'ffi'
ffi.cdef[[
typedef enum {
    OT_INT64,
    OT_FP,
    OT_STR,
    OT_BOOL,
    OT_NULL,
    OT_LAST_PRIMITIVE = OT_NULL,
    OT_HASHTAB,
    OT_ARRAY,
    OT_ROOT /* type of dummy object introduced during parsing process */
} obj_ty_t;

struct obj_tag;
typedef struct obj_tag obj_t;

struct obj_tag {
    obj_t* next;
    int32_t obj_ty;
    union {
        int32_t str_len;
        int32_t elmt_num; /* # of element of array/hashtab */
    };
};

/* primitive object */
typedef struct {
    obj_t common;
    union {
        char* str_val;
        int64_t int_val;
        double db_val;
    };
} obj_primitive_t;

struct obj_composite_tag;
typedef struct obj_composite_tag obj_composite_t;
struct obj_composite_tag {
    obj_t common;
    obj_t* subobjs;
    obj_composite_t* reverse_nesting_order;
    uint32_t id;
};

struct json_parser;

/* Export functions */
struct json_parser* jp_create(void);
obj_t* jp_parse(struct json_parser*, const char* json, uint32_t len);
const char* jp_get_err(struct json_parser*);
void jp_destroy(struct json_parser*);
]]

local cobj_ptr_t = ffi.typeof("obj_composite_t*")
local pobj_ptr_t = ffi.typeof("obj_primitive_t*")
local obj_ptr_t = ffi.typeof("obj_t*")

local ffi_cast = ffi.cast
local ffi_string = ffi.string

local _M = {}
local ok, tab_new = pcall(require, "table.new")
if not ok then
    tab_new = function (narr, nrec) return {} end
end

local jp_lib

--[[ Find shared object file package.cpath, obviating the need of setting
   LD_LIBRARY_PATH
]]
local function find_shared_obj(cpath, so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open

    for k in string_gmatch(cpath, "[^;]+") do
        local so_path = string_match(k, "(.*/)")
        so_path = so_path .. so_name

        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(so_path)
        if f ~= nil then
            io.close(f)
            return so_path
        end
    end
end

local function load_json_parser()
    if jp_lib ~= nil then
        return jp_lib
    else
        local so_path = find_shared_obj(package.cpath, "libljson.so")
        if so_path ~= nil then
            jp_lib = ffi.load(so_path)
            return jp_lib
        end
    end
end

function _M.create()
end

local ty_int64 = 0
local ty_fp = 1
local ty_str = 2
local ty_bool = 3
local ty_null = 4
local ty_last_primitive = 4
local ty_hashtab = 5
local ty_array= 6

local create_primitive
local create_array
local create_hashtab
local convert_obj
local tonumber = tonumber

create_primitive = function(obj)
    local ty = obj.common.obj_ty
    if ty == ty_int64 then
        return tonumber(obj.int_val)
    elseif ty == ty_str then
        return ffi_string(obj.str_val, obj.common.str_len)
    elseif ty == ty_null then
        return nil
    elseif ty == ty_bool then
        if obj.int_val == 0 then
            return false
        else
            return true
        end
    else
        return tonumber(obj.db_val)
    end

    return nil, "Unknown primitive type"
end

create_array = function(array, cobj_array)
    local elmt_num = array.common.elmt_num
    local elmt_list = array.subobjs

    -- HINT: The representation of an array-obj [e1, e2,..., en]
    --   is en->...->e2->e1
    local result = tab_new(elmt_num, 0)
    for iter = 1, elmt_num do
        local elmt = elmt_list

        local elmt_obj
        if elmt.obj_ty <= ty_last_primitive then
            local err;
            elmt_obj, err = create_primitive(ffi_cast(pobj_ptr_t, elmt))
            if err then
                return nil, err
            end
        else
            local cobj = ffi_cast(cobj_ptr_t, elmt);
            elmt_obj = cobj_array[cobj.id + 1]
        end

        result[elmt_num - iter + 1] = elmt_obj
        elmt_list = elmt_list.next
    end

    cobj_array[array.id + 1] = result

    return result;
end

create_hashtab = function(hashtab, cobj_array)
    local elmt_num = hashtab.common.elmt_num
    local elmt_list = hashtab.subobjs

    -- HINT: The representation of a hash-obj {k1,v1,...,kn:vn}
    --   is vn->kn->...->v1->k1.
    local result = tab_new(0, elmt_num / 2)
    for _ = 1, elmt_num, 2 do
        local val = elmt_list
        elmt_list = elmt_list.next

        local key = ffi_cast(pobj_ptr_t, elmt_list)
        local key_obj = ffi_string(key.str_val, key.common.str_len)

        local val_obj = nil
        if val.obj_ty <= ty_last_primitive then
            local err;
            val_obj, err = create_primitive(ffi_cast(pobj_ptr_t, val))
            if err then
                return nil, err
            end
        else
            local cobj = ffi_cast(cobj_ptr_t, val);
            val_obj = cobj_array[cobj.id + 1]
        end

        result[key_obj] = val_obj;
        elmt_list = elmt_list.next
    end

    cobj_array[hashtab.id + 1] = result

    return result
end

convert_obj = function(obj, cobj_array)
    local ty = obj.obj_ty
    if ty <= ty_last_primitive then
        return create_primitive(ffi_cast(pobj_ptr_t, obj))
    elseif ty == ty_array then
        return create_array(ffi_cast(cobj_ptr_t, obj), cobj_array)
    else
        return create_hashtab(ffi_cast(cobj_ptr_t, obj), cobj_array)
    end
end

-- Create an array big enough to accommodate elmt_num + 2 elements.
-- If cobj_vect is big enough, return it; otherwise, create a new one.
local function create_cobj_vect(cobj_vect, elmt_num)
    local array_size = elmt_num + 2
    local cap = cobj_vect[0]
    if cap < 400 and cap >= array_size then
        return cobj_vect
    end

    cobj_vect = tab_new(array_size, 1)
    cobj_vect[0] = array_size
    return cobj_vect
end

-- set each element to be nil, such that they can be GC-ed ASAP.
local function clean_cobj_vect(cobj_vect, elmt_num)
    for iter = 1, elmt_num + 2 do
        cobj_vect[iter] = nil
    end
end

-- #########################################################################
--
--      "Export" functions
--
-- #########################################################################
local setmetatable = setmetatable
local mt = { __index = _M }

function _M.new()
    if not jp_lib then
        load_json_parser()
    end

    if not jp_lib then
        return nil, "fail to load libjson.so"
    end

    local parser_inst = jp_lib.jp_create()
    if parser_inst ~= nil then
        ffi.gc(parser_inst, jp_lib.jp_destroy)
    else
        return nil, "Fail to create JSON parser, likely due to OOM"
    end

    local cobj_vect = tab_new(100, 1)
    if cobj_vect then
        cobj_vect[0] = 100
    else
        return nil, "fail to create intermediate array"
    end

    local self = {
        cobj_vect = cobj_vect,
        parser = parser_inst
    }

    return setmetatable(self, mt)
end

function _M.decode(self, json)
    --[[
    if not self then
        return nil, "JSON parser was not initialized properly"
    end]]

    local objs = jp_lib.jp_parse(self.parser, json, #json)
    if objs == nil then
        return nil, ffi_string(jp_lib.jp_get_err(self.parser))
    end

    local ty = objs.obj_ty
    if ty <= ty_last_primitive then
        return convert_obj(objs)
    end

    local composite_objs = ffi_cast(cobj_ptr_t, objs)
    local elmt_num = composite_objs.id
    local cobj_vect = create_cobj_vect(self.cobj_vect, elmt_num)
    self.cobj_vect = cobj_vect

    local last_val
    repeat
        last_val = convert_obj(ffi_cast(obj_ptr_t, composite_objs), cobj_vect)
        composite_objs = composite_objs.reverse_nesting_order
    until composite_objs == nil

    clean_cobj_vect(cobj_vect, elmt_num)

    return last_val
end

-- return:
--  1). array of strings in the input JSON
--  2). error message if error occur
--
--  1) could be nil if no string at all is found, if 1) is non-nil
--     element with index 0 is the size of the array
--
function _M.get_strings(self, json)

    -- step 1: decode the input JSON
    local objs = jp_lib.jp_parse(self.parser, json, #json)
    if objs == nil then
        return nil, ffi_string(jp_lib.jp_get_err(self.parser))
    end

    local ty = objs.obj_ty
    if ty <= ty_last_primitive then
        -- The enclosing object must be either a hashtab or array
        return nil, "malformed JSON"
    end

    local composite_objs = ffi_cast(cobj_ptr_t, objs)
    local str_count = 0

    -- step 2: count the number of strings
    repeat
        local elmt_num = composite_objs.common.elmt_num
        local elmt_list = composite_objs.subobjs

        -- go through all element
        for iter = 1, elmt_num do
            local elmt = elmt_list
            elmt_list = elmt_list.next

            if elmt.obj_ty == ty_str then
                str_count = str_count + 1
            end
        end
        composite_objs = composite_objs.reverse_nesting_order
    until composite_objs == nil

    if str_count == 0 then
        return
    end

    -- step 3: collect all strings
    local str_array = tab_new(str_count, 1)
    composite_objs = ffi_cast(cobj_ptr_t, objs)
    local idx = 1

    repeat
        local elmt_num = composite_objs.common.elmt_num
        local elmt_list = composite_objs.subobjs

        -- go through all elements
        for iter = 1, elmt_num do
            local elmt = elmt_list
            elmt_list = elmt_list.next

            if elmt.obj_ty == ty_str then
                elmt = ffi_cast(pobj_ptr_t, elmt)
                str_array[idx] = ffi_string(elmt.str_val, elmt.common.str_len)
                idx = idx + 1
            end
        end
        composite_objs = composite_objs.reverse_nesting_order
    until composite_objs == nil

    str_array[0] = str_count;

    return str_array
end

-- #########################################################################
--
--      Debugging and Misc
--
-- #########################################################################
local print_primitive
local print_table
local print_var
local print = print
local string_format = string.format
local tostring = tostring
local pairs = pairs
local type = type
local io_write = io.write

print_primitive = function(luadata)
    if type(luadata) == "string" then
        io_write(string_format("\"%s\"", luadata))
    else
        io_write(tostring(luadata))
    end
end

print_table = function(array)
    io_write("{");
    local elmt_num = 0
    for k, v in pairs(array) do
        if elmt_num > 0 then
            io_write(", ")
        end

        print_primitive(k)
        io_write(":")
        print_var(v)
        elmt_num = elmt_num + 1
    end
    io_write("}");
end
print_var = function(var)
    if type(var) == "table" then
        print_table(var)
    else
        print_primitive(var)
    end
end

function _M.debug(luadata)
    print_var(luadata)
    print("")
end

return _M
