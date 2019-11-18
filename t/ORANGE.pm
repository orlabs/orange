package t::ORANGE;

use Cwd qw(cwd);
use Test::Nginx::Socket::Lua::Stream -Base;

repeat_each(1);
log_level('info');
no_long_string();
no_shuffle();
worker_connections(128);

my $pwd = cwd();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $main_config = $block->main_config;
    $main_config .= <<_EOC_;
    env ORANGE_CONF;
_EOC_

    $block->set_value("main_config", $main_config);


    my $http_config = $block->http_config;
    $http_config .= <<_EOC_;
    sendfile on;

    charset UTF-8;

    resolver 114.114.114.114;

    client_body_buffer_size 1m;

    client_max_body_size 1m;

    upstream default_upstream {
        server 127.0.0.1:1981;
    }

    lua_package_path  "$pwd/deps/share/lua/5.1/?.lua;$pwd/deps/share/lua/5.1/orange/?.lua;$pwd/?.lua;$pwd/t/?.lua;/usr/share/lua/5.1/?.lua;/usr/local/lor/?.lua;;";
    lua_package_cpath "$pwd/deps/lib64/lua/5.1/?.so;$pwd/deps/lib/lua/5.1/?.so;/usr/lib64/lua/5.1/?.so;;";
    lua_code_cache on;

    lua_shared_dict orange_data 20m;  # should not removed. used for orange data, e.g. plugins configurations..

    lua_shared_dict status 1m; # used for global statistic, see plugin: stat
    lua_shared_dict waf_status 1m; # used for waf statistic, see plugin: waf
    lua_shared_dict monitor 10m; # used for url monitor statistic, see plugin: monitor
    lua_shared_dict rate_limit 10m; # used for rate limiting count, see plugin: rate_limiting
    lua_shared_dict property_rate_limiting 10m; # used for rate limiting count, see plugin: rate_limiting

    error_log logs/error.log;

    init_by_lua_block {
        local orange = require("orange.orange")
        local env_orange_conf = os.getenv("ORANGE_CONF")

        local config_file = env_orange_conf or "$pwd" .. "/conf/orange.conf"
        local config, store = orange.init({
            config = config_file
        })

        -- the orange context
        context = {
            orange = orange,
            store = store,
            config = config
        }
    }

    init_worker_by_lua_block {
        local orange = context.orange
        orange.init_worker()
    }

    # API Server
    server {
        listen 1980;
        location / {
            content_by_lua_block {
                local main = require("api.main")
                main:run()
            }
        }
    }

    server {
        listen 1981;
        location / {
            content_by_lua_block {
                require("servers.upstream").go()
            }
            more_clear_headers Date;
        }
    }

_EOC_

    $block->set_value("http_config", $http_config);


    my $config = $block->config;
    $config .= <<_EOC_;
    location / {
        set \$upstream_host \$host;
        set \$upstream_url 'http://default_upstream';

        rewrite_by_lua_block {
            local orange = context.orange
            orange.redirect()
            orange.rewrite()
        }

        access_by_lua_block {
            local orange = context.orange
            orange.access()
        }

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header Host \$upstream_host;
        proxy_pass \$upstream_url;

        header_filter_by_lua_block {
            local orange = context.orange
            orange.header_filter()
        }

        body_filter_by_lua_block {
            local orange = context.orange
            orange.body_filter()
        }

        log_by_lua_block {
            local orange = context.orange
            orange.log()
        }
    }
_EOC_

    $block->set_value("config", $config);
});

1;
