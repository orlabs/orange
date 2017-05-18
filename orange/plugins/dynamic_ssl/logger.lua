--
-- Created by IntelliJ IDEA.
-- User: soul11201 <soul11201@gmail.com>
-- Date: 2017/5/19
-- Time: 18:19
-- To change this template use File | Settings | File Templates.
--

-- 日志
local log = {}
local log_plugin_name = " [DynamicSSL] "
function log.errlog(...)
    ngx.log(ngx.ERR,log_plugin_name,...)
    ngx.log(ngx.ERR,"\n",debug.traceback());
end

function log.infolog(...)
    ngx.log(ngx.INFO,log_plugin_name,...)
end

return log

