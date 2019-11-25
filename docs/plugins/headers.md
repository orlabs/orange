## Header Rewrite Plugin

Used to rewrite `header` information upstream of the request.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/headers/enable -d "enable=1"
```

### Add Selectors to Plugin

```shell
curl http://127.0.0.1:7777/headers/selectors -X POST -d '
{
    "name": "headers-selectors",
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
curl http://127.0.0.1:7777/headers/selectors/{selector_id}/rules -X POST -d
{
    "name": "headers-one",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "=",
                "value": "/plugin_headers"
            }
        ]
    },
    "extractor": {
        "type": 1,
        "extractions": []
    },
    "handle": {
        "log": true
    },
    "headers": [
        {
            "type": "normal",
            "override": "1",
            "name": "X-API-Engine",
            "value": "orange"
        }
    ],
    "enable": true
}
```

| Params Name        | Params Description   |
|----------------|----------|
|headers.type    | data extraction type，value of `normal` indicates `current value`, and `extraction` indicates `variable extraction`.|
|headers.override| overwrite data, value of `0` indicates `not cover`, and `1` indicates `cover`. |
|headers.name    | header name |
|headers.value   | header default value. |

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/headers/enable -d "enable=0"
```
