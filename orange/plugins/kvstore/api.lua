local ipairs = ipairs
local type = type
local tostring = tostring
local string_format = string.format
local cjson = require("cjson")
local xpcall = xpcall
local traceback = debug.traceback
local orange_db = require("orange.store.orange_db")
local BaseAPI = require("orange.plugins.base_api")

local function send_err_result(res, format, err)
    if format == "json" then
        res:status(500):json({
            success = false,
            msg = err
        })
    elseif format == "text" then
        res:status(500):send(err)
    elseif format == "html" then
        res:status(500):html(err)
    end
end

local function send_failed_result(res, format, err)
    if format == "json" then
        res:json({
            success = false,
            msg = err
        })
    elseif format == "text" then
        res:send(err)
    elseif format == "html" then
        res:html(err)
    end
end

local function send_success_result(res, format)
    if format == "json" then
        res:json({
            success = true,
            msg = "success"
        })
    elseif format == "text" then
        res:send("success")
    elseif format == "html" then
        res:html("success")
    end
end

local function send_result(res, format, value)
    if format == "json" then
        xpcall(function() 
            value = cjson.decode(value)
        end, function(err)
            local trace = traceback(err, 2)
            ngx.log(ngx.ERR, "decode as json format error: ", trace)
        end)

        res:json({
            success = true,
            data = value
        })
    elseif format == "text" then
        res:send(value or "")
    elseif format == "html" then
        res:html(value or "")
    end
end


local API = BaseAPI:new("kvstore-api", 2)

API:get("/kvstore/configs", function(store)
    res:json({
        success = true, 
        data = {
            enable = orange_db.get("kvstore.enable")
        }
    })
end)

API:post("/kvstore/enable", function(store)
    return function(req, res, next)
        local enable = req.body.enable
        if enable == "1" then enable = true else enable = false end

        local result = false
        
        local kvstore_enable = "0"
        if enable then kvstore_enable = "1" end
        local update_result = store:update({
            sql = "replace into meta SET `key`=?, `value`=?",
            params = { "kvstore.enable", kvstore_enable }
        })

        if update_result then
            local success, err, forcible = orange_db.set("kvstore.enable", enable)
            result = success
        else
            result = false
        end

        if result then
            res:json({
                success = true,
                msg = (enable == true and "开启kvstore成功" or "关闭kvstore成功")
            })
        else
            res:json({
                success = false,
                data = (enable == true and "开启kvstore失败" or "关闭kvstore失败")
            })
        end
    end
end)

API:get("/kvstore/fetch_config", function(store)
    return function(req, res, next)
        local data = {}
        
        -- 查找enable
        local enable, err1 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "kvstore.enable" }
        })

        if err1 then
            return res:json({
                success = false,
                msg = "get enable error"
            })
        end

        if enable and type(enable) == "table" and #enable == 1 and enable[1].value == "1" then
            data.enable = true
        else
            data.enable = false
        end

        -- 查找其他配置
        local conf, err2 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "kvstore.conf" }
        })
        if err2 then
            return res:json({
                success = false,
                msg = "get conf error"
            })
        end

        if conf and type(conf) == "table" and #conf == 1 then
            data.conf = cjson.decode(conf[1].value)
        else
            data.conf = {}
        end

        res:json({
            success = true,
            data = data
        })
    end
end)

-- update the local cache to data stored in db
API:post("/kvstore/sync", function(store)
    return function(req, res, next)
        local data = {}
        -- 查找enable
        local enable, err1 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "kvstore.enable" }
        })

        if err1 then
            return res:json({
                success = false,
                msg = "get enable error"
            })
        end

        if enable and type(enable) == "table" and #enable == 1 and enable[1].value == "1" then
            data.enable = true
        else
            data.enable = false
        end

        -- 查找其他配置，如rules 、conf等
        local conf, err2 = store:query({
            sql = "select `value` from meta where `key`=?",
            params = { "kvstore.conf" }
        })
        if err2 then
            return res:json({
                success = false,
                msg = "get conf error"
            })
        end

        if conf and type(conf) == "table" and #conf == 1 then
            data.conf = cjson.decode(conf[1].value)
        else
            data.conf = {}
        end

        local ss, err3, forcible = orange_db.set("kvstore.enable", data.enable)
        if not ss or err3 then
            return res:json({
                success = false,
                msg = "update local enable error"
            })
        end
        ss, err3, forcible = orange_db.set_json("kvstore.conf", data.conf)
        if not ss or err3 then
            return res:json({
                success = false,
                msg = "update local conf error"
            })
        end

        res:json({
            success = true
        })
    end
end)

API:get("/kvstore/configs", function(store)
    return function(req, res, next)
        res:json({
            success = true,
            data = {
                enable = orange_db.get("kvstore.enable"),
                conf = orange_db.get_json("kvstore.conf")
            }
        })
    end
end)

-- new
API:post("/kvstore/configs", function(store)
    return function(req, res, next)
        local conf = req.body.conf
        local success, data = false, {}
        
        -- 插入或更新到mysql
        local update_result = store:update({
            sql = "replace into meta SET `key`=?, `value`=?",
            params = { "kvstore.conf", conf }
        })

        if update_result then
            local result, err, forcible = orange_db.set("kvstore.conf", conf)
            success = result
            if success then
                data.conf = cjson.decode(conf)
                data.enable = orange_db.get("kvstore.enable")
            end
        else
            success = false
        end

        res:json({
            success = success,
            data = data
        })
    end
end)

 -- modify
API:put("/kvstore/configs", function(store)
    return function(req, res, next)
        local conf = req.body.conf
        local success, data = false, {}
        
        -- 插入或更新到mysql
        local update_result = store:update({
            sql = "replace into meta SET `key`=?, `value`=?",
            params = { "kvstore.conf", conf }
        })

        if update_result then
            local result, err, forcible = orange_db.set("kvstore.conf", conf)
            success = result
            if success then
                data.conf = cjson.decode(conf)
                data.enable = orange_db.get("kvstore.enable")
            end
        else
            success = false
        end

        res:json({
            success = success,
            data = data
        })
    end
end)

API:get("/kvstore/get", function(store)
    return function(req, res, next)
        local dict = req.query.dict
        local key = req.query.key
        local format = req.query.format
        if format ~= "html" and format ~= "text" and format ~= "json" then 
            format = "json"
        end

        if not dict or not key or dict == "" or key == "" then
            return send_err_result(res, format, "error params.")
        end

        local block = false
        local conf = orange_db.get_json("kvstore.conf")
        if conf then
            local blacklist, whitelist = conf.blacklist, conf.whitelist
            if blacklist and next(blacklist) then
                for _, v in ipairs(blacklist) do
                    if v.dict == dict and v.key == key then
                        block = true
                        break
                    end
                end
            end

            local contains
            if whitelist and next(whitelist) then
                for _, v in ipairs(whitelist) do
                    if v.dict == dict and v.key == key then
                        contains = true
                        break
                    end
                end
            end

            if contains then 
                block = false
            end
        end

        if block == true then
            return send_err_result(res, format, string_format("not allowed to get ngx.shared.%s[%s]", dict, key))
        end

        local ngx_shared_dict = ngx.shared[dict]
        if not ngx_shared_dict then
            return send_err_result(res, format, string_format("ngx.shared.%s not exists", dict))
        end
        
        local value = ngx_shared_dict:get(key)
        ngx.log(ngx.INFO, dict, " ", key, " ", format, " v:", value)
        send_result(res, format, value)
    end
end)

API:post("/kvstore/set", function(store)
    return function(req, res, next)
        local dict = req.body.dict
        local key = req.body.key
        local value = req.body.value
        local exptime = req.body.exptime -- seconds
        local vtype = req.body.vtype
        local format = req.body.format
        local log = req.body.log

        if format ~= "html" and format ~= "text" and format ~= "json" then 
            format = "json"
        end

        if exptime and tonumber(exptime) then
            exptime = tonumber(exptime)
        end

        if vtype ~= "number" and vtype ~= "string" then 
            vtype = "string"
        end

        if vtype == "number" then
            value = tonumber(value)
            if not value then
                return send_failed_result(res, format, "value is nil or it's not a number.")
            end
        elseif type == "string" then
            value = tostring(value)
        end

        if log == "true" then
            log = true
        end

        if not dict or not key or dict == "" or key == "" then
            return send_failed_result(res, format, "error params.")
        end

        local block = false
        local conf = orange_db.get_json("kvstore.conf")
        if conf then
            local blacklist, whitelist = conf.blacklist, conf.whitelist
            if blacklist and next(blacklist) then
                for _, v in ipairs(blacklist) do
                    if v.dict == dict and v.key == key then
                        block = true
                        break
                    end
                end
            end

            local contains
            if whitelist and next(whitelist) then
                for _, v in ipairs(whitelist) do
                    if v.dict == dict and v.key == key then
                        contains = true
                        break
                    end
                end
            end

            if contains then 
                block = false
            end
        end

        if block == true then
            return send_failed_result(res, format, string_format("not allowed to set ngx.shared.%s[%s]", dict, key))
        end

        local ngx_shared_dict = ngx.shared[dict]
        if not ngx_shared_dict then
            return send_failed_result(res, format, string_format("ngx.shared.%s not exists", dict))
        end
        
        local success, err, forcible
        if exptime and exptime >= 0 then
            success, err, forcible = ngx_shared_dict:set(key, value, exptime)
        else
            success, err, forcible = ngx_shared_dict:set(key, value)
        end

        if log then
            ngx.log(ngx.INFO, string_format("kvstore-set, dict: %s, key: %s, value: [[%s]], success: %s", dict, key, value, success))
        end

        if success then
            send_success_result(res, format)
        else
            send_failed_result(res, format, err)
        end
    end
end)


return API
