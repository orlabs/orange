## URI 重定向插件

该插件用于重定向 `URL` 请求。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/redirect/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/redirect/selectors -X POST -d '
{
    "name": "redirect-selectors",
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
curl http://127.0.0.1:7777/redirect/selectors/{selector_id}/rules -X POST -d
{
    "name": "redirect-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/redirect_rewrite"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "handle": {
        "url_tmpl": "http://www.google.cn",
        "trim_qs": false,
        "redirect_status": "301",
        "log": true
    },
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|handle.uri_tmpl | 重定向URL，例如： `http://www.google.cn`。|
|handle.trim_qs | 清除Query参数，值为 `true` 表示 `清除`, 为 `false` 表示 `不清除`。|
|handle.redirect_status | 重定向 `HTTP` 状态码, 值可以是 `301` 或 `302`。|
|handle.log      | 是否记录日志, 值为 `true` 表示 `记录日志`, 为 `false` 表示 `不记录日志`。 |

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/redirect/enable -d "enable=0"
```
