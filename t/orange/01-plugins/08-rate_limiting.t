use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable rate_limiting plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/rate_limiting/enable', ngx.HTTP_POST, {
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



=== TEST 2: add rate_limiting selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/rate_limiting/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"rate_limiting-selectors",
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



=== TEST 3: add rate_limiting route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/rate_limiting/selectors/" .. selector("rate_limiting") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "rate_limiting-uri",
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
                    "handle": {
                        "period": 60,
                        "count": 2,
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



=== TEST 4: test rate_limiting request
--- pipelined_requests eval
["GET /plugin_rate_limiting", "GET /plugin_rate_limiting", "GET /plugin_rate_limiting"]
--- error_code eval
[200, 200, 429]
--- no_error_log
[error]



=== TEST 5: disable rate_limiting plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/rate_limiting/enable', ngx.HTTP_POST, {
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
