## Proxy Request Divide Plugin

Used to divide request.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/divide/enable -d "enable=1"
```

### Add Selectors to Plugin

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

| Params Name    | Params Description |
|----------------|--------------------|
|name            | selectors name. |
|type            | selectors type, value of `0` indicates `all request` and `1` indicates `custom request`. |
|handle.continue | selectors action, value of `true` indicates `continue selector` and `false` indicates  `skip selector`. |
|handle.log      | selectors log, value of `true` indicates `record logs` and `false` indicates  `not record logs`. |

### Add URI to Plugin

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
    "enable": true
}
```

| Params Name    | Params Description |
|----------------|--------------------|
|upstream_host   | upstream host address, example: `example.com`. |
|upstream_url    | upstream request address, example: `http://127.0.0.1:1982`. |
|log             | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Test Plugin

> send request

```shell
curl -X GET http://127.0.0.1/plugin_divide
HTTP/1.1 200 OK
```

> see upstream `access.log`

```shell
127.0.0.1 - [26/Sep/2019:10:52:20 +0800] example.com GET /plugin_divide HTTP/1.1 200 38 - curl/7.29.0 - 0.000 199 107
```

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/divide/enable -d "enable=0"
```
