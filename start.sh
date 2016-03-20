#!/usr/bin/env bash

#nginx -p /data/workspace/lor/orange_tmp -c /data/workspace/lor/orange/conf/nginx.conf
pid=`cat /data/workspace/lor/orange/logs/nginx.pid`
echo "kill "$pid
kill -s QUIT $pid

#ORANGE_CONF=orange/orange.conf && nginx -p `pwd` -c ./conf/nginx.conf
nginx -p `pwd` -c ./conf/nginx.conf