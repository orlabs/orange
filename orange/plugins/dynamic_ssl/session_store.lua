local ssl_sess = require "ngx.ssl.session"
local ssl_util = require "orange.plugins.dynamic_ssl.ssl_util"
local errlog = ssl_util.log.errlog
local save_it = ssl_util.session_cache.session_save_timer



local sess_id, err = ssl_sess.get_session_id()

if not sess_id then
    errlog( "failed to get session ID: ", err)
    return
end

local sess, err = ssl_sess.get_serialized_session()
if not sess then
    errlog("failed to get SSL session from the ",
        "current connection. err:", err,'session ID:',sess_id)
    return
end

-- for the best performance, we should avoid creating a closure
-- dynamically here on the hot code path. Instead, we should
-- put this function in one of our own Lua module files. this
-- example is just for demonstration purposes...

local ok, err = ngx.timer.at(0, save_it, sess_id, sess)
if not ok then
    errlog("failed to create a 0-delay timer: ", err)
    return
end