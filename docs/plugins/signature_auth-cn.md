## Signature Auth 插件

该插件用于 `Signature Auth` 请求认证。

### 开启插件

```shell
curl -XPOST http://127.0.0.1:7777/signature_auth/enable -d "enable=1"
```

### 为插件添加 Selectors

```shell
curl http://127.0.0.1:7777/signature_auth/selectors -X POST -d '
{
    "name": "signature_auth-selectors",
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
curl http://127.0.0.1:7777/signature_auth/selectors/{selector_id}/rules -X POST -d
{
    "name": "signature_auth-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/redirect_signature_auth"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": [
            {
                "type": "Query",
                "name": "engine"
            },
            {
                "type": "Query",
                "name": "type"
            },
            {
                "type": "Query",
                "name": "sign"
            }
        ]
    },
    "handle": {
        "credentials": {
            "signame": "sign",
            "secretkey": "orange"
        },
        "code": 401,
        "log": true
    },
    "enable": true
}
```

| 参数名称        | 参数描述       |
|----------------|---------------|
|extractor.type | 变量提取方式，值为 `1` 表示 `索引提取式`，为 `2` 表示 `模板提取式`。|
|extractor.extractions[].type | 计算变量提取来源，默认为 `Query`。|
|extractor.extractions[].name | 计算变量名称。|
|handle.credentials.signame | 保存签名变量名称，当前变量必需保存到 `extractor.extractions[]` 中。|
|handle.credentials.secretkey | 签名秘钥。|
|handle.code     | 认证失败 `HTTP` 状态码，值可以是 `4XX` 级别。|
|handle.log      | 是否记录日志，值为 `true` 表示 `记录日志`，为 `false` 表示 `不记录日志`。 |

### 测试插件

> 认证成功请求

```shell
curl -X GET http://127.0.0.1/plugin_signature_auth?engine=orange&type=gateway&sign=1cb43a0498f3389c71476173b5c494e4
HTTP/1.1 200 OK
```

> 认证失败请求

```shell
curl -X GET http://127.0.0.1/plugin_signature_auth
HTTP/1.1 401 Unauthorized
```

### 关闭插件

```shell
curl -XPOST http://127.0.0.1:7777/signature_auth/enable -d "enable=0"
```

### 相关问题

- [#72](https://github.com/orlabs/orange/issues/72)
