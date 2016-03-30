#!/usr/bin/env bash

current_path=`pwd`
pid=""

if [ -f ./logs/nginx.pid ]
then
	pid=`cat ./logs/nginx.pid`
fi

if [ "$pid" = "" ]
then
	echo "start orange for openresty-china usage..."
else
	echo "kill the old process: "$pid
	kill -s QUIT $pid
	echo "restart orange for openresty-china usage..."
fi

mkdir -p logs
nginx -p $current_path -c ./nginx.conf