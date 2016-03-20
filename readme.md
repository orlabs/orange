# Orange

Orange是一个OpenResty API监控和管理组件

[中文](./README.md)&nbsp;&nbsp;[English](./README_EN.md)

## 介绍

Orange是一个基于OpenResty的API Gateway，提供API监控和管理，实现了防火墙、访问统计、流量切分、API重定向等功能。



##安装说明

### 安装 Nginx / OpenResty


```
wget https://openresty.org/download/ngx_openresty-1.9.7.1.tar.gz
tar -xvzf ngx_openresty-1.9.7.1.tar.gz
cd ngx_openresty-1.9.7.1
sudo su
./configure --prefix=/opt/orange --user=nginx --group=nginx --with-http_stub_status_module --with-luajit
make
make install
```

>以上使用的是openresty-1.9.7.1，当openresty发布更新的稳定版本时，也可以使用最新的稳定版本


### 部署 Orange

待续..



### 匹配规则

0只有一项条件(1的子集)，1指有多项条件全为and连接，2为多项条件全为or连接，3为复杂表达式


### TODO

WAF或者其他规则的监控