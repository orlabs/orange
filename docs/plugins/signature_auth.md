## Signature Auth Plugin

Used to `Signature Auth` requests authentication.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/signature_auth/enable -d "enable=1"
```

### Add Selectors to Plugin

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

| Params Name    | Params Description |
|----------------|--------------------|
|name            | selectors name. |
|type            | selectors type, value of `0` indicates `all request` and `1` indicates `custom request`. |
|handle.continue | selectors action, value of `true` indicates `continue selector` and `false` indicates  `skip selector`. |
|handle.log      | selectors log, value of `true` indicates `record logs` and `false` indicates  `not record logs`. |

### Add URI to Plugin

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
                "value": "/plugin_signature_auth"
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

| Params Name    | Params Description |
|----------------|--------------------|
|extractor.type | variable extraction type, value of `1` indicates `index extraction`, and `2` indicates `template extraction`.|
|extractor.extractions[].type | variable extraction source, default `Query`.|
|extractor.extractions[].name | calculated variable name. |
|handle.credentials.signame | save the signature variable name, current variable must be saved to `extractor.extractions[]`. |
|handle.credentials.secretkey | signing key. |
|handle.code | authentication failure `HTTP` status code, value is `4XX` level. |
|handle.log      | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Test Plugin

> authentication success request

```shell
curl -X GET http://127.0.0.1/plugin_signature_auth?engine=orange&type=gateway&sign=1cb43a0498f3389c71476173b5c494e4
HTTP/1.1 200 OK
```

> authentication request failure

```shell
curl -X GET http://127.0.0.1/plugin_signature_auth
HTTP/1.1 401 Unauthorized
```

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/signature_auth/enable -d "enable=0"
```

### Issues

- [#72](https://github.com/orlabs/orange/issues/72)
