local ipairs = ipairs
local tonumber = tonumber
local cjson = require("cjson")
local IO = require("orange.utils.io")
local Store = require("orange.store.base")
local FileStore = Store:extend()

function FileStore:new(options)
    options = options or {}
    FileStore.super.new(self, options.name or "file-store")
    self.file_path = options.file_path
    self.data = {}
    if not self.loaded then
        ngx.log(ngx.ERR, "load file store configurations... ", options.file_path)
        self:load()
        self.loaded = true
    end
end

function FileStore:load()
    local status, err = pcall(function()
        local config_content = IO.read_file(self.file_path)
        local config = cjson.decode(config_content)
        if config then
            self.data = config
            self.data.redirect_config = self.data.redirect_config or {}
            self.data.rewrite_config = self.data.rewrite_config or {}
            self.data.waf_config = self.data.waf_config or {}
        end
    end)
    if not status or err then
        ngx.log(ngx.ERR, "load file store error: ", err)
        os.exit(1)
    end
end

function FileStore:get_redirect_config()
    return self.data.redirect_config
end

function FileStore:get_rewrite_config()
    return self.data.rewrite_config
end

function FileStore:get_waf_config()
    return self.data.waf_config
end

function FileStore:set(k, v)
    if not k or k == "" then return false, "nil key." end
    ngx.log(ngx.DEBUG, " file_store \"" .. self._name .. "\" get:" .. k)
    self.data[k] = v
end

function FileStore:get(k)
    if not k or k == "" then return nil end
    ngx.log(ngx.DEBUG, " file_store \"" .. self._name .. "\" set:" .. k, " v:", v)
    return self.data[k]
end


function FileStore:store()
    local config_content = cjson.encode(self.data)
    local result, err = IO.write_to_file(self.file_path, config_content)

    if result then
    else
        ngx.log(ngx.ERR, " file_store store error:", err)
    end
end



return FileStore