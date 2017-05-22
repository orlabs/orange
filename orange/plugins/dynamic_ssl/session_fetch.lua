local ssl_sess = require "ngx.ssl.session"
local log = require "orange.plugins.dynamic_ssl.logger"
local cache =  require "orange.plugins.dynamic_ssl.session_cache"

local errlog = log.errlog

local sess_id, err = ssl_sess.get_session_id()
if not sess_id then
    errlog( "failed to get session ID. err:", err)
    return
end

local sess, err = cache:get(sess_id)
if not sess or ngx.null == sess then
    if  err then
        errlog("failed to look up the session by ID [", sess_id, "] err:", err)
    end

    return
end


sess = ngx.decode_base64(sess)

local ok, err = ssl_sess.set_serialized_session(sess)
if not ok then
    errlog("failed to set SSL session for ID ", sess_id,": ", err)
    return
end

