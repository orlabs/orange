## 全局统计插件

用于获取当前`Orange`节点的运行状态， 如`工作路径`、`程序版本`、`启动时间`、`总请求数`、`连接数`等。

### 开启插件

该插件为系统插件，默认开启。

### 获取插件信息

#### 请求地址

```bash
curl -XGET http://127.0.0.1:7777/stat/status
```

#### 响应信息

|名称                |描述|
|-------------------|-----------|
|address            | 当前节点`host`地址。 |
|con_active         | 当前活跃的客户端连接数，包括等待连接数。 |
|con_idle           | 当前等待请求的空闲客户端连接数。 |
|con_reading        | `Nginx` 正在读取请求标头的当前连接数。 |
|con_writing        | `Nginx` 将响应写回客户端的当前连接数。 |
|con_rw             | 读写连接的总和。 |
|start_time         | 节点启动时间戳。 |
|timestamp          | 当前时间戳. |
|load_timestamp     | 节点加载时间戳，等同于 `start_time`。 |
|nginx_version      | 当前 `Nginx` 版本。 |
|ngx_lua_version    | 当前 `ngx_lua` 版本。 |
|ngx_prefix         | `Nginx` 工作目录。 |
|orange_version     | 当前 `Orange` 版本。 |
|request_2xx        | `2xx` 请求次数。 |
|request_3xx        | `3xx` 请求次数。 |
|request_4xx        | `4xx` 请求次数。 |
|request_5xx        | `5xx` 请求次数。 |
|total_count        | 请求总数。 |
|total_request_time | 总请求时间（秒）。 |
|total_success_count| 成功请求总数。 |
|traffic_read       | 总读取流量（字节）。 |
|traffic_write      | 总写入流量（字节）。 |
|worker_count       | `Nginx` 工作 `worker` 总数。 |

### 禁用插件

该插件不可以禁用。
