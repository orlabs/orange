use t::ORANGE 'no_plan';

no_shuffle();
no_root_location();
run_tests();

__DATA__

=== TEST 1: enable redirect plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/redirect/enable', ngx.HTTP_POST, {
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



=== TEST 2: add redirect selectors
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/redirect/selectors', ngx.HTTP_POST, {
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



=== TEST 3: add redirect 301 route (id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/redirect/selectors/" .. selector("redirect") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "redirect-301",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin/redirect/301"
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



=== TEST 4: test redirect 301
--- request
GET /plugin/redirect/301 HTTP/1.1
--- response_headers
Location: http://www.google.cn
--- error_code: 301
--- no_error_log
[error]



=== TEST 5: add redirect 302 route (id: 2)
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local selector = require("servers.api").selector
            local code, message = t("/redirect/selectors/" .. selector("redirect") .. "/rules", ngx.HTTP_POST, {
                rule = [[{
                    "name": "redirect-302",
                    "judge": {
                        "type": 0,
                        "conditions": [
                            {
                                "type": "URI",
                                "operator": "=",
                                "value": "/plugin/redirect/302"
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
                        "redirect_status": "302",
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



=== TEST 6: test redirect 302
--- request
GET /plugin/redirect/302
--- response_headers
Location: http://www.google.cn
--- error_code: 302
--- no_error_log
[error]



=== TEST 7: disable redirect plugin
--- config
    location /t {
        content_by_lua_block {
            local t = require("servers.api").go
            local code, message = t('/redirect/enable', ngx.HTTP_POST, {
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
