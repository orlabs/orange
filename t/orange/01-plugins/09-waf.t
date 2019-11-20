use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable waf plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/waf/enable', ngx.HTTP_POST, {
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



=== TEST 2: add waf selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/waf/selectors', ngx.HTTP_POST, {
                selector = [[{
                    "name":"waf-selectors",
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



=== TEST 3: add waf deny route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/waf/selectors/" .. selector("waf") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "waf-deny-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_waf_deny"
                            }
                        ]
                    },
                    "handle": {
                        "perform": "deny",
                        "code": 403,
                        "stat": true,
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
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 4: test waf deny uri
--- request
GET /plugin_waf_deny
--- error_code chomp
403
--- no_error_log
[error]



=== TEST 5: add waf allow route (id: 2)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/waf/selectors/" .. selector("waf") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "waf-allow-uri",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin_waf_allow"
                            }
                        ]
                    },
                    "handle": {
                        "perform": "allow",
                        "stat": true,
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
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 6: test waf allow uri
--- request
GET /plugin_waf_allow
--- response_body
uri: /plugin_waf_allow
--- error_code chomp
200
--- no_error_log
[error]



=== TEST 7: disable waf plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/waf/enable', ngx.HTTP_POST, {
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
