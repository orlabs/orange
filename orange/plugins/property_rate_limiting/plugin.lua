local _M = {}
_M.name = 'property-rate-limiting-plugin'
_M.api_name = 'property-rate-limiting-api'
_M.require_prefix = 'orange.plugins.property_rate_limiting.';
_M.plug_reponse_header_prefix = 'X-PropertyRateLimiting-Remaining-';
_M.table_name = 'property_rate_limiting'

_M.shared_dict_rw_lock_name = 'property_rate_limiting_counter_lock'
_M.message_forbidden = 'PropertyRateLimiting-Forbidden-Rule';
_M.name_for_log = 'PropertyRateLimiting';

return _M
