## WAF Firewall Plugin

Used to request filtering of request traffic.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/waf/enable -d "enable=1"
```

### Add Selectors to Plugin

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

| Params Name    | Params Description |
|----------------|--------------------|
|name            | selectors name. |
|type            | selectors type, value of `0` indicates `all request` and `1` indicates `custom request`. |
|handle.continue | selectors action, value of `true` indicates `continue selector` and `false` indicates  `skip selector`. |
|handle.log      | selectors log, value of `true` indicates `record logs` and `false` indicates  `not record logs`. |

### Add URI to Plugin

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

| Params Name    | Params Description |
|----------------|--------------------|
|handle.perform  | deny access, value of `deny` indicates `deny access`, and `allow` indicates `allow access`. |
|handle.code     | response http status code. |
|handle.stat     | statistics numbers, value of `true` indicates `statistics`，and `false` indicates `not statistics`. |
|handle.log      | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Test Plugin

> allow requests

```shell
curl -X GET http://127.0.0.1/plugin_waf
HTTP/1.1 200 OK
```

> deny requests

```shell
curl -X GET http://127.0.0.1/plugin_waf
HTTP/1.1 403 Forbidden
```

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/waf/enable -d "enable=0"
```
