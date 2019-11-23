## URI 重写插件

该插件用于重写请求上游的 `URI` 信息。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/rewrite/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/rewrite/selectors -X POST -d '
{
    "name": "rewrite-selectors",
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
curl http://127.0.0.1:7777/rewrite/selectors/{selector_id}/rules -X POST -d
{
    "name": "rewrite-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_rewrite"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "handle": {
        "uri_tmpl": "/plugin_rewrite",
        "log": true
    },
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|handle.uri_tmpl | 新的上游 `URI`。|
|handle.log      | 是否记录日志, 值为 `true` 表示 `记录日志`, 为 `false` 表示 `不记录日志`。 |

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/rewrite/enable -d "enable=0"
```
