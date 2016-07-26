###全局统计插件API

全局统计插件当前默认为开启状态，暂不提供关闭功能


**请求**

URI                 | Method 
------------------- | ---- 
/stat/status        | Get 


**参数**   
无 

**返回结果** 

```
{
	"success": true,
    "data": {
    	"start_time": 1466415807, //orange启动时的时间戳

        "total_count": 0, //总请求量
        "total_success_count": 0, //成功请求数量，http_status < 400

        "request_2xx": 0, //http_status=200的请求量
        "request_3xx": 0,
        "request_4xx": 0,
        "request_5xx": 0,

        "total_request_time": 0, //所有请求消耗总时间，单位秒
        "traffic_read": 0, //所有请求读入的字节数
        "traffic_write": 0, //所有请求响应写出的字节数
        
        "con_active": "1", //ngx.var.connections_active
        "con_waiting": "0" //ngx.var.connections_waiting
        "con_reading": "0", //ngx.var.connections_reading
        "con_writing": "1", //ngx.var.connections_writing
    }
}
```