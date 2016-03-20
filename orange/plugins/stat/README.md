### 流量统计插件

使用之前需要在OpenResty配置文件中添加以下配置项：

```
lua_shared_dict status 1m;
```

shared dict的大小需根据实际应用配置。


##### TODO

- 临时给定一个url，监控它的访问情况，以及请求详情，比如ua、host、ip等等
