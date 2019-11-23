## Jwt Auth Plugin

Used to `Jwt Auth` requests authentication.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/jwt_auth/enable -d "enable=1"
```

### Add Selectors to Plugin

```shell
curl http://127.0.0.1:7777/jwt_auth/selectors -X POST -d '
{
    "name": "jwt_auth-selectors",
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
curl http://127.0.0.1:7777/jwt_auth/selectors/{selector_id}/rules -X POST -d
{
    "name": "jwt_auth-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_jwt_auth"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "handle": {
        "credentials": {
            "secret": "orange",
            "payload": [
                {
                    "type": 1,
                    "key": "name",
                    "target_key": "X-Orange-Name"
                }
            ]
        },
        "code": 401,
        "log": true
    },
    "enable": true
}
```

| Params Name    | Params Description |
|----------------|--------------------|
|handle.credentials.secret | data signing key. |
|handle.credentials.payload[].type | payload param type, default is `1` indicates `header`.|
|handle.credentials.payload[].key | payload param name. |
|handle.credentials.payload[].target_key | payload param value. |
|handle.code | authentication failure `HTTP` status code, value is `4XX` level. |
|handle.log      | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Test Plugin

> request success for header

```shell
curl -X GET http://127.0.0.1/plugin_jwt_auth -H "Authorization: JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSmFua28ifQ.cJ-3zovM7Wq2gAS2YQ_udk4PW9iRzLbREHI1Yesycb8"
HTTP/1.1 200 OK
```

> request success for query

```shell
curl -X GET http://127.0.0.1/plugin_jwt_auth?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSmFua28ifQ.cJ-3zovM7Wq2gAS2YQ_udk4PW9iRzLbREHI1Yesycb8
HTTP/1.1 200 OK
```

> request failure

```shell
curl -X GET http://127.0.0.1/plugin_jwt_auth
HTTP/1.1 401 Unauthorized
```

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/jwt_auth/enable -d "enable=0"
```
