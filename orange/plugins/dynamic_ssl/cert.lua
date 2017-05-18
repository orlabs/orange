local ssl_util = require "orange.plugins.dynamic_ssl.ssl_util"
local ssl = require "ngx.ssl"

local cert_pkey_hash = ssl_util.cert_pkey_hash
local errlog = ssl_util.log.errlog

local name, err = ssl.server_name()
if not name then
    errlog("could not get sni; err: ",err)
    return
end

-- clear the fallback certificates and private keys
-- set by the ssl_certificate and ssl_certificate_key directives in nginx conf

local ok, err = ssl.clear_certs()
if not ok then
    errlog("failed to clear existing (fallback) certificates; err: ",err)
    return ngx.exit(ngx.ERROR)
end

local pem_cert_chain,err = cert_pkey_hash:get_cert(name)
if not pem_cert_chain then
    errlog("not found the cert. Check dashbaord sni config!",
        "err:", err, '[sni:',name,']')
    return ngx.exit(ngx.ERROR)
end

local der_cert_chain, err = ssl.cert_pem_to_der(pem_cert_chain)
if not der_cert_chain then
    errlog( "failed to convert certificate chain from PEM to DER.",
        "Check dashbaord cert config!",
        "err:", err, 'cert data: [', pem_cert_chain, ']' )
    return ngx.exit(ngx.ERROR)
end

local ok, err = ssl.set_der_cert(der_cert_chain)
if not ok then
    errlog("failed to set DER cert. err:", err)
    return ngx.exit(ngx.ERROR)
end

local pem_pkey,err = cert_pkey_hash:get_pkey(name)

if not pem_pkey then
    errlog("not found the pkey. Check dashbaord sni config!",
        "err:", err, "[sni:", name, ']')
    return ngx.exit(ngx.ERROR)
end

local der_pkey,err = ssl.priv_key_pem_to_der(pem_pkey)
if not der_pkey then
    errlog("failed to convert private key from PEM to DER.",
        "Check dashbaord pkey config!",
        "err:", err, "pkey data:",pem_pkey)
    return ngx.exit(ngx.ERROR)
end

local ok, err = ssl.set_der_priv_key(der_pkey)
if not ok then
    errlog("failed to set DER private key: ", err)
    return ngx.exit(ngx.ERROR)
end