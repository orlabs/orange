#!/usr/bin/env bash

current_path=`pwd`
pid=""

if [ -f $current_path/logs/nginx.pid ]
then
	pid=`cat $current_path/logs/nginx.pid`
fi

nginx=`which nginx`
if [ $? -ne 0 ]
then
    echo "nginx was not install" 1>&2;
    exit 1
fi

if [ "$pid" = "" ]
then
	echo "start orange.."
else
	echo "kill "$pid
	#kill -s QUIT $pid
	$nginx -p `pwd` -c ./conf/nginx.conf -s stop
	echo "restart orange.."
fi

mkdir -p logs
$nginx -p `pwd` -c ./conf/nginx.conf
