# Orange

<a href="./README_zh.md" style="font-size:13px">中文</a> <a href="./README.md" style="font-size:13px">English</a> 


Orange是一个基于OpenResty的API网关.


### 安装

#### 安装依赖

- OpenResty: 版本应在1.9.7.3+
- [lor](https://github.com/sumory/lor)框架: 版本在v0.1.0+
- libuuid.so
    - Orange依赖libuuid生成uuid
    - centos用户可通过命令`yum install libuuid-devel`安装，其它情况请自行google
- MySQL
    - 从0.2.0版本开始，Orange去除了本地文件存储的方式，目前仅提供MySQL存储支持.

#### 数据表导入MySQL

- 在MySQL中创建数据库，名为orange
- 将install/orange-v0.3.0.sql导入到orange库中

#### 修改配置文件

Orange有两个配置文件，一个是`orange.conf`，用于配置插件、存储方式和内部集成的默认Dashboard，另一个是`conf/nginx.conf`用于配置Nginx(OpenResty).

orange.conf的配置如下，请按需修改:

```javascript
{
    "plugins": [ //可用的插件列表，若不需要可从中删除，系统将自动加载这些插件的开放API并在7777端口暴露
        "stat", 
        "monitor", 
        "redirect", 
        "rewrite", 
        "basic_auth",
        "waf", 
        "divide"
    ],

    "store": "mysql",//目前仅支持mysql存储
    "store_mysql": { //MySQL配置
        "timeout": 5000,
        "connect_config": {//连接信息，请修改为需要的配置
            "host": "127.0.0.1",
            "port": 3306,
            "database": "orange",
            "user": "root",
            "password": "",
            "max_packet_size": 1048576
        },
        "pool_config": {
            "max_idle_timeout": 10000,
            "pool_size": 3
        },
        "desc": "mysql configuration"
    },

    "dashboard": {//默认的Dashboard配置.
        "auth": false, //设置为true，则需要用户名、密码才能登录Dashboard使用，默认的用户名和密码为admin/orange_admin
        "session_secret": "y0ji4pdj61aaf3f11c2e65cd2263d3e7e5", //加密cookie用的盐，自行修改即可
        "whitelist": [//不需要鉴权的uri，如登录页面，无需修改此值
            "^/auth/login$",
            "^/error/$"
        ]
    },

    "api": {//API server配置
        "auth_enable": true,//访问API时是否需要授权
        "credentials": [//HTTP Basic Auth配置，仅在开启auth_enable时有效，自行添加或修改即可
            {
                "username":"api_username",
                "password":"api_password"
            }
        ]
    }
}
```

conf/nginx.conf里是一些nginx相关配置，请自行检查并按照实际需要更改或添加配置.


#### 启动

执行`sh start.sh`即可启动orange.

- 内置的Dashboard可通过`http://localhost:9999`访问
- API Server默认在`7777`端口监听，如不需要API Server可删除nginx.conf里对应的配置


### 文档

- 项目文档: [官网](http://orange.sumory.com/docs), 目前只有0.1.*版本
- API文档: [开放API](./api/README.md)


### Docker

[http://hub.docker.com/r/syhily/orange](http://hub.docker.com/r/syhily/orange) 由[@syhily](https://github.com/syhily)维护.


### 贡献者

- 雨帆([@syhily](https://github.com/syhily))


### See also

Orange的插件设计参考自[Kong](https://github.com/Mashape/kong).

### License

[MIT](./LICENSE)
