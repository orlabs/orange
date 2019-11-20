use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable key_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/key_auth/enable', ngx.HTTP_POST, {
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



=== TEST 2: add key_auth selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/key_auth/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"key_auth-selectors",
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



=== TEST 3: add key_auth route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/key_auth/selectors/" .. selector("key_auth") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "key_auth-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_key_auth"
                            }
                        ]
                    },
                    "handle": {
                        "credentials": [
                            {
                                "type": 1,
                                "key": "Authorization",
                                "target_value": "Key orange"
                            }
                        ],
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



=== TEST 4: test key_auth authentication failed
--- request
GET /plugin_key_auth
--- error_code chomp
401
--- no_error_log
[error]



=== TEST 5: test key_auth authentication succeed
--- request
GET /plugin_key_auth
--- more_headers
Authorization: Key orange
--- response_body
uri: /plugin_key_auth
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: disable key_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/key_auth/enable', ngx.HTTP_POST, {
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
