local BasePlugin = require("orange.plugins.base_handler")
local cjson = require "cjson"
local producer = require "resty.kafka.producer"

local  KafkaHandler = BasePlugin:extend()
KafkaHandler.PRIORITY = 2000

function KafkaHandler:new(store)
    KafkaHandler.super.new(self, "kafka-plugin")
    self.store = store
end

local function errlog(...)
    ngx.log(ngx.ERR,'[Kafka]',...)
end

local do_log = function(log_table)
    -- 定义kafka broker地址，ip需要和kafka的host.name配置一致
    local broker_list = context.config.plugin_config.kafka.broker_list
    local kafka_topic = context.config.plugin_config.kafka.topic
    local producer_config =  context.config.plugin_config.kafka.producer_config

    -- 定义json便于日志数据整理收集
    -- 转换json为字符串
    local message = cjson.encode(log_table);
    -- 定义kafka异步生产者
    local bp = producer:new(broker_list, producer_config)
    -- 发送日志消息,send第二个参数key,用于kafka路由控制:
    -- key为nill(空)时，一段时间向同一partition写入数据
    -- 指定key，按照key的hash写入到对应的partition
    local ok, err = bp:send(kafka_topic, nil, message)

    if not ok then
        errlog("kafka send err:", err)
        return
    end
end

local function log(premature,log_table)
    if premature then
        errlog("timer premature")
        return
    end
    local ok,err = pcall(do_log,log_table)

    if not ok then
        errlog("failed to record log by kafka",err)

        local ok,err = ngx.timer.at(0,log,log_table)
        if not ok then
            errlog ("faild to create timer",err)
        end
    end

end

--  log_format  main '$remote_addr - $remote_user [$time_local] "$request" '
-- '$status $body_bytes_sent "$http_referer" '
-- '"$http_user_agent" "$request_time" "$ssl_protocol" "$ssl_cipher" "$http_x_forwarded_for"'
-- '"$upstream_addr" "$upstream_status" "$upstream_response_length" "$upstream_response_time"';

function KafkaHandler:log()
    local log_json = {}
    log_json["remote_addr"] = ngx.var.remote_addr and ngx.var.remote_addr or '-'
    log_json["remote_user"] = ngx.var.remote_user and ngx.var.remote_user or '-'
    log_json["time_local"] = ngx.var.time_local and ngx.var.time_local or '-'
    log_json['request'] = ngx.var.request and ngx.var.request or '-'
    log_json["status"] = ngx.var.status and ngx.var.status or '-'
    log_json["body_bytes_sent"] = ngx.var.body_bytes_sent and ngx.var.body_bytes_sent or '-'
    log_json["http_referer"] = ngx.var.http_referer and ngx.var.http_referer or '-'
    log_json["http_user_agent"] = ngx.var.http_user_agent and ngx.var.http_user_agent or '-'
    log_json["request_time"] = ngx.var.request_time and ngx.var.request_time or '-'

    log_json["uri"]=ngx.var.uri and ngx.var.uri or '-'
    log_json["args"]=ngx.var.args and ngx.var.args or '-'
    log_json["host"]=ngx.var.host and ngx.var.host or '-'
    log_json["request_body"]=ngx.var.request_body and ngx.var.request_body or '-'


    log_json['ssl_protocol']                    = ngx.var.ssl_protocol and ngx.var.ssl_protocol or ' -'
    log_json['ssl_cipher']                  = ngx.var.ssl_cipher and ngx.var.ssl_cipher or ' -'
    log_json['upstream_addr']                   = ngx.var.upstream_addr and ngx.var.upstream_addr or ' -'
    log_json['upstream_status']                 = ngx.var.upstream_status and ngx.var.upstream_status or ' -'
    log_json['upstream_response_length']                    = ngx.var.upstream_response_length and ngx.var.upstream_response_length or ' -'

    log_json["http_x_forwarded_for"] = ngx.var.http_x_forwarded_for and ngx.var.http_x_forwarded_for or '-'
    log_json["upstream_response_time"] = ngx.var.upstream_response_time and ngx.var.upstream_response_time or '-'
    log_json["upstream_url"] = "http://" .. ngx.var.upstream_url .. ngx.var.upstream_request_uri or '';
    log_json["request_headers"] = ngx.req.get_headers();
    log_json["response_headers"] = ngx.resp.get_headers();
    log_json["server_addr"] = ngx.var.server_addr

    local ok,err = ngx.timer.at(0,log,log_json)
    if not ok then
        errlog ("faild to create timer",err)
    end

end


return KafkaHandler
