#!/usr/bin/env bash

current_path=`pwd`
pid=""

if [ -f ./logs/nginx.pid ]
then
	pid=`cat ./logs/nginx.pid`
fi

if [ "$pid" = "" ]
then
	echo "start orange for all use cases..."
else
	echo "kill the old process: "$pid
	kill -s QUIT $pid
	echo "restart orange for all use cases..."
fi

mkdir -p logs
nginx -p $current_path -c ./nginx.conf