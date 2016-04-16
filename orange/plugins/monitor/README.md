### url监控、访问统计插件

使用之前需要在OpenResty配置文件中添加以下配置项：

```
lua_shared_dict monitor 10m;
```

shared dict的大小需根据实际应用配置。


#### TODO

- 匹配规则排他性？