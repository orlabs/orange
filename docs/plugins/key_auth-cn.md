## Key Auth 插件

该插件用于 `Key Auth` 请求认证。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/key_auth/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/key_auth/selectors -X POST -d '
{
    "name": "key_auth-selectors",
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
curl http://127.0.0.1:7777/key_auth/selectors/{selector_id}/rules -X POST -d
{
    "name": "key_auth-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/redirect_key_auth"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "handle": {
        "credentials": [
            {
                "type": 1,
                "key": "Authorization",
                "target_value": "Key orange"
            }
        ],
        "code": 401,
        "log": true
    },
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|handle.credentials.type | 认证参数类型，值为 `1` 表示 `header`，为 `2` 表示 `query`，为 `3` 表示 `post`。|
|handle.credentials.key | 认证参数名称。|
|handle.credentials.target_value | 认证参数值。|
|handle.code | 认证失败 `HTTP` 状态码，值可以是 `4XX` 级别。|
|handle.log      | 是否记录日志，值为 `true` 表示 `记录日志`，为 `false` 表示 `不记录日志`。 |

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/key_auth/enable -d "enable=0"
```
