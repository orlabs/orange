local ssl_util = {}
local share_cache =   require "orange.plugins.dynamic_ssl.session_cache"
local cert_pkey_hash_data = require "orange.plugins.dynamic_ssl.cert_pkey_data"
local log = require "orange.plugins.dynamic_ssl.logger"


ssl_util.cert_pkey_hash = cert_pkey_hash_data
ssl_util.log = log
ssl_util.session_cache = share_cache

return ssl_util