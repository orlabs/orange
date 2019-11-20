use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable signature_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/signature_auth/enable', ngx.HTTP_POST, {
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



=== TEST 2: add signature_auth selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/signature_auth/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"signature_auth-selectors",
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



=== TEST 3: add signature_auth route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/signature_auth/selectors/" .. selector("signature_auth") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "signature_auth-uri",
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



=== TEST 4: test signature_auth authentication failed
--- request
GET /plugin_signature_auth
--- error_code chomp
401
--- no_error_log
[error]



=== TEST 5: test signature_auth authentication succeed
--- request
GET /plugin_signature_auth?engine=orange&type=gateway&sign=1cb43a0498f3389c71476173b5c494e4
--- response_body
uri: /plugin_signature_auth
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: disable signature_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/signature_auth/enable', ngx.HTTP_POST, {
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
