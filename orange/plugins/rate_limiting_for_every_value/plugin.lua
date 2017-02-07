local _M = {}
_M.name = 'rate-limiting-for-every-value-plugin'
_M.api_name = 'rate-limiting-api'
_M.require_prefix = 'orange.plugins.rate_limiting_for_every_value.';
_M.plug_reponse_header_prefix = 'X-RateLimit-Remaining-';
_M.table_name = 'rate_limiting_for_every_value'

_M.ngx_shared_dict_name = 'rate_limiting_for_every_value';
_M.shared_dict_rw_lock_name = 'rate_limiting_for_every_value_counter_lock'

return _M
