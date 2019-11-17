#!/bin/bash

set -ex

before_install() {
    sudo cpanm --notest Test::Nginx
    mysql -uroot -e 'CREATE DATABASE IF NOT EXISTS orange;'
    mysql -uroot orange < install/orange-master.sql;
}

do_install() {
    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    sudo apt-get update --fix-missing
    sudo apt-get -y install software-properties-common
    sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    sudo apt-get update

    sudo apt-get install -y openresty openresty-resty luarocks

    sudo luarocks make --lua-dir=/usr/local/openresty/luajit rockspec/orange-master-0.rockspec --tree=deps --only-deps --local

    git clone https://github.com/iresty/test-nginx.git test-nginx

}

run_tests() {
    export OPENRESTY_PREFIX="/usr/local/openresty"
    export PATH=$OPENRESTY_PREFIX/nginx/sbin:$OPENRESTY_PREFIX/luajit/bin:$OPENRESTY_PREFIX/bin:$PATH
    prove -I test-nginx/lib -r t
}

option=$1

case ${option} in
    before_install)
        before_install
        ;;
    do_install)
        do_install
        ;;
    run_tests)
        run_tests
        ;;
    *)
        echo "$1 option is undefined."
        ;;
esac
