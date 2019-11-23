## Rate Limiting Plugin

Used to requests `Rate Limiting`.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/rate_limiting/enable -d "enable=1"
```

### Add Selectors to Plugin

```shell
curl http://127.0.0.1:7777/rate_limiting/selectors -X POST -d '
{
    "name": "rate_limiting-selectors",
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
curl http://127.0.0.1:7777/rate_limiting/selectors/{selector_id}/rules -X POST -d
{
    "name": "rate_limiting-plugin",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_rate_limiting"
            }
        ]
    },
    "extractor": {
    },
    "handle": {
        "period": 60,
        "count": 2,
        "log": true
    },
    "enable": true
}
```

| Params Name    | Params Description |
|----------------|--------------------|
|handle.period | time period. |
|handle.count | maximum number of visits in the time period. |
|handle.log      | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Test Plugin

```shell
curl -X GET http://127.0.0.1/plugin_rate_limiting
HTTP/1.1 200 OK

curl -X GET http://127.0.0.1/plugin_rate_limiting
HTTP/1.1 200 OK

...

curl -X GET http://127.0.0.1/plugin_rate_limiting
HTTP/1.1 429 Too Many Requests
```

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/rate_limiting/enable -d "enable=0"
```
