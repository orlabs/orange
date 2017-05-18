local orange_db = require("orange.store.orange_db")
local BasePlugin = require("orange.plugins.base_handler")

local DynamicSSLHandler = BasePlugin:extend()
DynamicSSLHandler.PRIORITY = 2000

function DynamicSSLHandler:new(store)
    DynamicSSLHandler.super.new(self, "dynamic_ssl-plug")
    self.store = store
end

function DynamicSSLHandler:sync_cache()

    local ssl_util = require "orange.plugins.dynamic_ssl.ssl_util"
    local enable = orange_db.get("dynamic_ssl.enable")
    local meta = orange_db.get_json("dynamic_ssl.meta")
    local selectors = orange_db.get_json("dynamic_ssl.selectors")
    local ordered_selectors = meta and meta.selectors

    local cert_pkey_hash = ssl_util.cert_pkey_hash

    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        return
    end

    for _, sid in ipairs(ordered_selectors) do
        local selector = selectors[sid]
        if selector and selector.enable == true then
            local rules = orange_db.get_json("dynamic_ssl.selector." .. sid .. ".rules")
            if not rules or type(rules) ~= "table" or #rules <= 0 then
                return false
            end

            for _, rule in ipairs(rules) do
                if rule.enable == true then
                    cert_pkey_hash:set_cert(rule.handle.sni,rule.handle.cert)
                    cert_pkey_hash:set_pkey(rule.handle.sni,rule.handle.pkey)
                end
            end
        end

    end
end


return DynamicSSLHandler