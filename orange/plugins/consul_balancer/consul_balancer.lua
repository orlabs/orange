--https://github.com/xytis/lua-consul-balancer
local orange_db = require("orange.store.orange_db")
local utils = require("orange.utils.utils")
local date = require("orange.lib.date")
local stat = require("orange.plugins.consul_balancer.stat")

local orange = require("orange.orange")
local consul_kv = require("orange.store.consul_kv")
--

-- Dependencies
local http = require "resty.http"
local balancer = require "ngx.balancer"
local json = require "cjson"

local WATCH_RETRY_TIMER = 0.5

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
  new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 16) -- Change the second number.

_M.VERSION = "0.01"
_M._cache = {}
_M._watchs = {}

local function _sanitize_uri(consul_uri)
  -- TODO: Ensure that uri has <proto>://<host>[:<port>] scheme
  return consul_uri
end

local function _timer(...)
  local ok, err = ngx.timer.at(...)
  if not ok then
    ngx.log(ngx.ERR, "[FATAL] consul.balancer: failed to create timer: ", err)
  end
end

local function _parse_service(content, opts)
  if not content then
    return nil, nil, "JSON decode error"
  end
    
  local service = {}
  local rules = {}
  service.index = opts[3]
  service.upstreams = {}
  for k, v in pairs(content) do
    local passing = true
    local checks = v["Checks"]
    for i, c in pairs(checks) do
      if c["Status"] ~= "passing" then
        passing = false
      end
    end

    if passing then
      local s = v["Service"]
      local na = v["Node"]["Address"]
      local ip = s["Address"] ~= "" and s["Address"] or na
      table.insert(service.upstreams, {
          address = ip,
          port = s["Port"],
        })

        table.insert(rules, {
          enable = true,
          id = "1",
          target = ip .. ":" .. s["Port"],
          weight = 10,
          time = utils.now(),
        })  
    end
  end

  return rules, service
end

local function _persist(service_name, service)
  if _M.shared_cache then
    _M.shared_cache:set(service_name, json.encode(service))
    return
  end

  _M._cache[service_name] = service
end

local function _persist_rule(info, rules)
  local success, err, forcible = orange_db.set_json("consul_balancer.selector." .. info.id .. ".rules", rules)
  if err or not success then
      ngx.log(ngx.ERR, "update local rules of selector error, err:", err)
      return false
  end
end

local function _aquire(service_name)
  if _M.shared_cache then
    local service_json = _M.shared_cache:get(service_name)
    return service_json and json.decode(service_json) or nil
  end

  return _M._cache[service_name]
end

local function _aquire_watch(service_name)
    local service_json = _M.shared_cache_watch:get(service_name)
    return service_json and json.decode(service_json) or nil 
end

local function _persist_watch(service_name, service)
    _M.shared_cache_watch:set(service_name, json.encode(service))
end

local function _remove_watch(service_name)
  _M.shared_cache_watch:delete(service_name)
end

local function _check(ctx, service_index)
  local args = {
    index = service_index,
    wait = orange.data.config.consul.interval
  }

  if ctx.dc ~= nil then
    args.dc = ctx.dc
  end

  if ctx.tag ~= nil then
    args.tag = ctx.tag
  end

  if ctx.near ~= nil then
    args.near = ctx.near
  end

  if ctx["node-meta"] ~= nil then
    args["node-meta"] = ctx["node-meta"]
  end

  return consul_kv.check_service(ctx.service, args)
end

local function _validate_service_descriptor(service_descriptor)
  if type(service_descriptor) == "string" then
    service_descriptor = {
      id = nil,
      name = service_descriptor,
      service = service_descriptor,
      tag = nil
    }
  elseif type(service_descriptor) == "table" then
    if service_descriptor.id == nil then
      return nil, "missing id field in service_descriptor"
    end

    if service_descriptor.name == nil then
      return nil, "missing name field in service_descriptor"
    end
    
    if service_descriptor.service == nil then
      service_descriptor.service = service_descriptor.name
    end
  end

  return service_descriptor
end

local ostime = os.time
-- signature must match nginx timer API
local function _watch(premature, service_descriptor)
  if premature then
    return nil
  end

  local service_index = 0
  local watch_name = "upstream_watch." .. service_descriptor.id
  local t = _aquire_watch(watch_name)
  local t1 = {
    t1 = t.t.dayfrc,
    t2 = t.t.daynum
  }
  ngx.log(ngx.NOTICE, "consul.balancer: started watching for changes in ", service_descriptor.name, "(", t1.t1, ",", t1.t2, ")")

  local tLast = ostime() + 90
  while t do
    local res, err = _check(service_descriptor, service_index)
    if res == nil then
      ngx.log(ngx.ERR, "consul.balancer: failed while watching for changes in ", service_descriptor.name, " retry scheduled")
      _timer(WATCH_RETRY_TIMER, _watch, service_descriptor)
      return nil
    end

    local rules, service, err = _parse_service(res, err)
    if err ~= nil then
        ngx.log(ngx.ERR, "consul.balancer: failed to parse consul response: ", err)
        return nil, nil, err
    end

    if ngx.worker.exiting() then
      ngx.log(ngx.ERR, "be force exiting")
      os.exit()
      return
    end

    -- TODO: Save only newer data from consul to reduce GC load
    service_index = service.index
    t = _aquire_watch(watch_name)                 
    if not t then
      break
    end

    if t1.t1 ~= t.t.dayfrc or t1.t2 ~= t.t.daynum then
      ngx.log(ngx.ERR, service_descriptor.name , " not my time(", t.t.dayfrc, ",", t.t.daynum, ")")
      return nil
    end

    _persist(service_descriptor.id, service)
    _persist_rule(service_descriptor, rules)
    
    if service_descriptor.log_consul then
      ngx.log(ngx.INFO, "consul.balancer: persisted service ", service_descriptor.name, "(", service_descriptor.id, 
                      ") index: ", service_index, " content: ", json.encode(service))
    end
    
    local tNow = ostime()
    if tNow > tLast then
      _timer(0, _watch, service_descriptor)
      return
    end
  end
  
  ngx.log(ngx.ERR, service_descriptor.name , " stop watching(", t1.t1, ",", t1.t2, ")")
end

function _M.watch(service_list)
  -- start watching on first worker only, skip for others (if shared storage provided)
  if ngx.worker.id() > 0 then
    if nil ~= _M.shared_cache then
      return
    end
  else
    if nil == _M.shared_cache then
      _M.set_shared_dict_name("consul_upstream", "consul_upstream_watch")
    end
  end

  for k,v in pairs(service_list) do
    _M.add_watch(v)
  end
end

function _M.round_robin(srv)
  if premature then
    return ngx.exit(500)
  end

  local service = _aquire(srv.id)
  if service == nil then
    ngx.log(ngx.ERR, "consul.balancer: no entry found for service: ", srv.name)
    return ngx.exit(500)
  end

  if service.upstreams == nil or #service.upstreams == 0 then
    ngx.log(ngx.ERR, "consul.balancer: no peers for service: ", srv.service)
    return ngx.exit(500)
  end

  if service.state == nil or service.state > #service.upstreams then
    service.state = 1
  end

  -- TODO: https://github.com/openresty/lua-resty-core/blob/master/lib/ngx/balancer.md#get_last_failure
  -- set max tries only at first attempt
  if not balancer.get_last_failure() then
    balancer.set_more_tries(#service.upstreams - 1)
  end
  
  -- Picking next upstream
  local upstream = service.upstreams[service.state]
  service.state = service.state + 1
  _persist(srv.id, service)
  local ok, err = balancer.set_current_peer(upstream["address"], upstream["port"])
  if not ok then
    ngx.log(ngx.ERR, "consul.balancer: failed to set the current peer", upstream["address"], ":", upstream["port"], ",", err)
    return ngx.exit(500)
  end

  local key = srv.id .. "_" .. upstream["address"] .. ":" .. upstream["port"]
  stat.count(key, 1)
  ngx.log(ngx.INFO, "round_robin ->", service.state, " ", upstream["address"], ":", upstream["port"])
end

function _M.set_shared_dict_name(dict_name, dict_watch_name)
  _M.shared_cache = ngx.shared[dict_name]
  _M.shared_cache_watch = ngx.shared[dict_watch_name]
  if not _M.shared_cache or not _M.shared_cache_watch then
    ngx.log(ngx.ERR, "consul.balancer: unable to access shared dict ", dict_name, " or ", dict_watch_name)
    return ngx.exit(ngx.ERROR)
  end
end

function _M.add_watch(service_descriptor)
  if premature then
    return
  end

  local service, err = _validate_service_descriptor(service_descriptor)
  if err == nil then
    local c = {}
    c.t = date()
    _persist_watch("upstream_watch." .. service.id, c)
    _timer(0, _watch, service)
    ngx.log(ngx.INFO, "add/update watch ", service.name)
    return
  end

  ngx.log(ngx.ERR, "consul.balancer: ", err)
end

function _M.remove_watch(service)
  if premature then
    return
  end

  _remove_watch("upstream_watch." .. service.id)
  ngx.log(ngx.INFO, "remove watch ", service.name , "(", service.id, ")")
end

return _M
