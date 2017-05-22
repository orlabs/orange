--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/5/19
-- Time: 18:15
-- To change this template use File | Settings | File Templates.
--
local log = require "orange.plugins.dynamic_ssl.logger"
local fact = require "orange.plugins.dynamic_ssl.redis"

local session_cache = {}

function session_cache:get(key)

    local red, err = fact:new()
    if not red then
        log.errlog(err)
        return red,err
    end
    local res,err = red:get(key)
    red:release_to_pool()
    return res, err

end

function session_cache:set(k, v)
    local red, err = fact:new()
    if not red then
        log.errlog(err)
        return false, err
    end
    red:set(k, v)
    red:expire(k, context.config.dynamic_ssl.ssl_session_timeout)
    red:release_to_pool()
    return true, err
end


function session_cache.session_save_timer(premature, sess_id, sess)
    local res, err = session_cache:set(sess_id, ngx.encode_base64(sess))
    if not res then
        log.errlog("failed to save the session by ID ",
            sess_id, ": ", err)
        return ngx.exit(ngx.ERROR)
    end
end

return session_cache

