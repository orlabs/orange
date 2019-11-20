use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable jwt_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/jwt_auth/enable', ngx.HTTP_POST, {
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



=== TEST 2: add jwt_auth selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/jwt_auth/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"jwt_auth-selectors",
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



=== TEST 3: add jwt_auth route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/jwt_auth/selectors/" .. selector("jwt_auth") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "jwt_auth-uri",
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



=== TEST 4: test jwt_auth authentication failed
--- request
GET /plugin_jwt_auth
--- error_code chomp
401
--- no_error_log
[error]



=== TEST 5: test jwt_auth authentication succeed
--- request
GET /plugin_jwt_auth
--- more_headers
Authorization: JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSmFua28ifQ.cJ-3zovM7Wq2gAS2YQ_udk4PW9iRzLbREHI1Yesycb8
--- response_body
uri: /plugin_jwt_auth
host: localhost
x-forwarded-scheme: http
x-forwarded-for: 127.0.0.1
x-real-ip: 127.0.0.1
connection: close
x-orange-name: Janko
authorization: JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSmFua28ifQ.cJ-3zovM7Wq2gAS2YQ_udk4PW9iRzLbREHI1Yesycb8
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: disable jwt_auth plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/jwt_auth/enable', ngx.HTTP_POST, {
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
