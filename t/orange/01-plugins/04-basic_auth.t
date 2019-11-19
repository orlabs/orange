use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable basic_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/basic_auth/enable', ngx.HTTP_POST, {
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



=== TEST 2: add basic_auth selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/basic_auth/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"basic_auth-selectors",
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



=== TEST 3: add basic_auth route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/basic_auth/selectors/" .. selector("basic_auth") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "basic_auth-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_basic_auth"
                            }
                        ]
                    },
                    "handle": {
                        "credentials": [
                            {
                                "username": "orange",
                                "password": "123456"
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



=== TEST 4: test basic_auth authentication failed
--- request
GET /plugin_basic_auth
--- error_code chomp
401
--- no_error_log
[error]



=== TEST 5: test basic_auth authentication succeed
--- request
GET /plugin_basic_auth
--- more_headers
Authorization: b3JhbmdlOjEyMzQ1Ng==
--- response_body
uri: /plugin_basic_auth
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: disable basic_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/basic_auth/enable', ngx.HTTP_POST, {
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
