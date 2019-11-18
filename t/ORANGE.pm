package t::ORANGE;

use Test::Nginx::Socket::Lua::Stream -Base;

repeat_each(1);
log_level('info');
no_long_string();
no_shuffle();
worker_connections(128);

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = $block->http_config;

    $block->set_value("http_config", $http_config);

    my $config = $block->config;

    $block->set_value("config", $config);

});

1;
