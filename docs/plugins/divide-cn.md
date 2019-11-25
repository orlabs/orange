## 代理请求划分插件

该插件用于划分请求到不同上游节点。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/divide/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/divide/selectors -X POST -d '
{
    "name": "divide-selectors",
    "type": 0,
    "judge": {},
    "handle": {
        "continue": true,
        "log": false
    },
    "enable": true
}'
```

| 参数名称        | 参数描述   |
|----------------|-----------|
|name            | 选择器名称。|
|type            | 选择器类型, 值为 `0` 时表示 `全部流量` ，为 `1` 时表示 `自定义流量` 。 |
|handle.continue | 选择器动作, 值为 `true` 时表示 `继续后续选择器`，为 `false` 时表示 `略过后续选择器`。 |
|handle.log      | 选择器日志, 值为 `true` 时表示 `记录日志`，为 `false` 时表示 `不记录日志`。 |

### 为插件添加 URI

```shell
curl http://127.0.0.1:7777/divide/selectors/{selector_id}/rules -X POST -d
{
    "name": "divide-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_divide"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "upstream_host": "example.com",
    "upstream_url": "http://127.0.0.1:1982",
    "log": true,
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|upstream_host | 上游主机地址，例如：`example.com`。 |
|upstream_url  | 上游请求地址，例如：`http://127.0.0.1:1982`。|
|log           | 是否记录日志，值为 `true` 表示 `记录日志`，为 `false` 表示 `不记录日志`。 |

### 测试插件

> 发送请求

```shell
curl -X GET http://127.0.0.1/plugin_divide
HTTP/1.1 200 OK
```

> 查看上游 `access.log`

```shell
127.0.0.1 - [26/Sep/2019:10:52:20 +0800] example.com GET /plugin_divide HTTP/1.1 200 38 - curl/7.29.0 - 0.000 199 107
```

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/divide/enable -d "enable=0"
```
