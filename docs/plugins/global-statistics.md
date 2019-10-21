## Global Statistics Plugin

Used to get the running status of the current `Orange` node, such as `Working Path`, `Program Version`, 
`Starting Time`, `Total Requests`, `Connections`, etc.

### Enable Plugin

This is a system plugin, default enable.

### Get Plugin Info

#### Request

```bash
curl -XGET http://127.0.0.1:7777/stat/status
```

#### Response

|name               |description|
|-------------------|-----------|
|address            | Current node `host` address. |
|con_active         | The current number of active client connections including Waiting connections. |
|con_idle           | The current number of idle client connections waiting for a request. |
|con_reading        | The current number of connections where `nginx` is reading the request header. |
|con_writing        | The current number of connections where `nginx` is writing the response back to the client. |
|con_rw             | Sum of reading and writing connections. |
|start_time         | Node start timestamp. |
|timestamp          | Current timestamp. |
|load_timestamp     | Node load timestamp. |
|nginx_version      | Current `Nginx` Version. |
|ngx_lua_version    | Current `ngx_lua` Version. |
|ngx_prefix         | `Nginx` working directory. |
|orange_version     | Current `Orange` Version. |
|request_2xx        | `2xx` request numbers. |
|request_3xx        | `3xx` request numbers. |
|request_4xx        | `4xx` request numbers. |
|request_5xx        | `5xx` request numbers. |
|total_count        | Total number of requests. |
|total_request_time | Total Request Time (seconds). |
|total_success_count| Total number of successful requests. |
|traffic_read       | Total Reading Traffic (bytes). |
|traffic_write      | Total Writing Traffic (bytes). |
|worker_count       | Total number of `Nginx` worker. |

### Disable Plugin

This plugin is not allowed to be disabled.
