## URL Redirect Plugin

Used to Redirect `URL` of the request.

### Enable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/redirect/enable -d "enable=1"
```

### Add Selectors to Plugin

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

| Params Name    | Params Description |
|----------------|--------------------|
|name            | selectors name. |
|type            | selectors type, value of `0` indicates `all request` and `1` indicates `custom request`. |
|handle.continue | selectors action, value of `true` indicates `continue selector` and `false` indicates  `skip selector`. |
|handle.log      | selectors log, value of `true` indicates `record logs` and `false` indicates  `not record logs`. |

### Add URI to Plugin

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
                "value": "/plugin_redirect"
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

| Params Name    | Params Description |
|----------------|--------------------|
|handle.uri_tmpl | redirect url, example: `http://www.google.cn`.|
|handle.trim_qs  | clear query, value of `true` indicates `clear query`, and `false` indicates `not clear query`.|
|handle.redirect_status | redirect http code, value is `301` or `302`.|
|handle.log      | record logs, value of `true` indicates `record logs`, and `false` indicates `not record logs`. |

### Disable Plugin

```shell
curl -XPOST http://127.0.0.1:7777/redirect/enable -d "enable=0"
```
