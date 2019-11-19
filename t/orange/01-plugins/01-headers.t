use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable headers plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/headers/enable', ngx.HTTP_POST, {
                enable = 1
            })
            ngx.status = code
            ngx.say(message)
        }
    }
--- request
GET /t
--- response_body
OK
--- no_error_log
[error]
--- error_code chomp
200



=== TEST 2: add headers selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/headers/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"headers-selectors",
                    "type":0,
                    "judge":{},
                    "handle":{
                        "continue":true,
                        "log":false
                    },
                    "enable":true
                }]],
            })
            ngx.status = code
            ngx.say(message)
        }
    }
--- request
GET /t
--- response_body
OK
--- no_error_log
[error]
--- error_code chomp
200



=== TEST 3: add headers route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/headers/selectors/" .. selector("headers") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
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
                }]]
            })
            ngx.status = code
            ngx.say(message)
        }
    }
--- request
GET /t
--- response_body
OK
--- no_error_log
[error]
--- error_code chomp
200



=== TEST 4: header cover
--- request
GET /plugin_headers
--- more_headers
X-API-Engine: nginx
--- response_body
uri: /plugin_headers
host: localhost
x-forwarded-scheme: http
x-forwarded-for: 127.0.0.1
x-real-ip: 127.0.0.1
connection: close
x-api-engine: orange
--- no_error_log
[error]
--- error_code chomp
200



=== TEST 5: header rewrite
--- request
GET /plugin_headers
--- response_body
uri: /plugin_headers
host: localhost
x-forwarded-scheme: http
x-forwarded-for: 127.0.0.1
x-real-ip: 127.0.0.1
connection: close
x-api-engine: orange
--- no_error_log
[error]
--- error_code chomp
200



=== TEST 6: disable headers plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/headers/enable', ngx.HTTP_POST, {
                enable = 0
            })
            ngx.status = code
            ngx.say(message)
        }
    }
--- request
GET /t
--- response_body
OK
--- no_error_log
[error]
--- error_code chomp
200
