#!/bin/sh

set -ex


OR_EXEC=`which openresty 2>&1`
echo $OR_EXEC
CHECK_OR_EXIST=`echo $OR_EXEC | grep ": no openresty" | wc -l`


LUA_JIT_DIR=`$OR_EXEC -V 2>&1 | grep prefix | grep -Eo 'prefix=(.*?)/nginx' | grep -Eo '/.*/'`
LUA_JIT_DIR="${LUA_JIT_DIR}luajit"
echo $LUA_JIT_DIR


LUA_ROCKS_EXEC=`which luarocks 2>&1`
echo $LUA_ROCKS_EXEC
CHECK_ROCKS_EXIST=`echo $LUA_ROCKS_EXEC | grep ": no luarocks" | wc -l`


LUA_ROCKS_VER=`luarocks --version | grep -Eo  "luarocks [0-9]+"`
echo $LUA_ROCKS_VER


UNAME=`uname`
echo $UNAME


do_install() {
    if [ "$UNAME" == "Darwin" ]; then
        luarocks install --lua-dir=$LUA_JIT_DIR orange --tree=/usr/local/orange/deps --local

    elif [ "$LUA_ROCKS_VER" == 'luarocks 3' ]; then
        luarocks install --lua-dir=$LUA_JIT_DIR orange --tree=/usr/local/orange/deps --local

    else
        luarocks install orange --tree=/usr/local/orange/deps --local
    fi
}

do_remove() {
    sudo rm -f /usr/local/bin/orange
    luarocks purge /usr/local/orange/deps --tree=/usr/local/orange/deps
}

option=$1
if [ !$option ]; then
    option='install'
fi
echo $option

case ${option} in
install)
    do_install "$@"
    ;;
remove)
    do_remove "$@"
    ;;
esac
