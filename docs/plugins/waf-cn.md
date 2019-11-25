## WAF 防火墙插件

该插件用于请求过滤请求流量。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/waf/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/waf/selectors -X POST -d '
{
    "name": "waf-selectors",
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
curl http://127.0.0.1:7777/waf/selectors/{selector_id}/rules -X POST -d
{
    "name": "waf-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_waf"
            }
        ]
    },
    "handle": {
        "perform": "deny",
        "code": 403,
        "stat": true,
        "log": true
    },
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|handle.perform | 是否拒绝访问，值为 `deny` 表示 `拒绝`，为 `allow` 表示 `通过`。|
|handle.code    | 响应 `HTTP` 状态码。|
|handle.stat    | 是否统计次数，值为 `true` 表示 `统计`，为 `false` 表示 `不记录统计`。|
|handle.log     | 是否记录日志，值为 `true` 表示 `记录日志`，为 `false` 表示 `不记录日志`。 |

### 测试插件

> 测试正常访问

```shell
curl -X GET http://127.0.0.1/plugin_waf
HTTP/1.1 200 OK
```

> 测试拒绝访问

```shell
curl -X GET http://127.0.0.1/plugin_waf
HTTP/1.1 403 Forbidden
```

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/waf/enable -d "enable=0"
```
