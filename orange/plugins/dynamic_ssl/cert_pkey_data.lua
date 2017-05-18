--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/5/19
-- Time: 18:18
-- To change this template use File | Settings | File Templates.
--

local log = require "orange.plugins.dynamic_ssl.logger"

-- cert pkey 数据库数据在内存中的缓存
local cert_pkey_hash_data = {}
function cert_pkey_hash_data:get(key)
    local c = ngx.shared.ssl_cert_pkey
    local handle = require "orange.plugins.dynamic_ssl.handler"

    local v,err = c:get(key)
    if not v then
        log.errlog(key," cert or pkey data not found in cache; err: ",err);
        handle:sync_cache()
        v,err = c:get(key)
    end

    return v,err;
end


function cert_pkey_hash_data:set(key,value)
    local c = ngx.shared.ssl_cert_pkey
    local success, e, out_of_zone = c:set(key,value)

    if not success then
        log.errlog('cache fail,err:',e);
    end

    if out_of_zone then
        log.errlog(" out of storage in the shared memory zone [ssl_cert_pkey] .")
    end

    return success,e
end

function cert_pkey_hash_data:get_cert(sni)
    return self:get(sni .. 'cert')
end

function cert_pkey_hash_data:get_pkey(sni)
    return self:get(sni .. 'pkey')
end

function cert_pkey_hash_data:set_cert(sni,cert)
    return self:set(sni .. 'cert', cert)
end

function cert_pkey_hash_data:set_pkey(sni,pkey)
    return self:set(sni .. 'pkey', pkey)
end

return cert_pkey_hash_data