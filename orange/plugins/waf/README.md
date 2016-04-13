### WAF防火墙插件

#### 使用说明

若开启了规则统计功能，使用之前需要在OpenResty配置文件中添加以下配置项：

```
lua_shared_dict waf_status 1m;
```

shared dict的大小需根据实际应用配置。

#### 特性

- 支持多条件匹配
- 拒绝访问时支持自定义状态码，如403，405等等
- 支持是否开启日志记录
- 支持访问规则统计，若支持此功能，请添加lua_shared_dict waf_status
