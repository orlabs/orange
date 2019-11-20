use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable divide plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/divide/enable', ngx.HTTP_POST, {
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



=== TEST 2: add divide selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/divide/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"divide-selectors",
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



=== TEST 3: add divide route (id: 1981)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/divide/selectors/" .. selector("divide") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "divide-1981-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_divide_1981"
                            }
                        ]
                    },
                    "extractor": {
                        "type": 1,
                        "extractions": []
                    },
                    "upstream_host": "a.com",
                    "upstream_url": "http://127.0.0.1:1981",
                    "log": true,
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
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 4: test divide route (id: 1981)
--- request
GET /plugin_divide_1981
--- response_body
host: a.com
uri: /plugin_divide_1981
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 5: add divide route (id: 1982)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/divide/selectors/" .. selector("divide") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "divide-1982-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_divide_1982"
                            }
                        ]
                    },
                    "extractor": {
                        "type": 1,
                        "extractions": []
                    },
                    "upstream_host": "b.com",
                    "upstream_url": "http://127.0.0.1:1982",
                    "log": true,
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
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: test divide route (id: 1982)
--- request
GET /plugin_divide_1982
--- response_body
host: b.com
uri: /plugin_divide_1982
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 7: disable divide plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/divide/enable', ngx.HTTP_POST, {
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
--- error_code chomp
200
--- no_error_log
[error]
