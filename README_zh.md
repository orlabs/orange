# Orange

 [![GitHub release](https://img.shields.io/github/release/sumory/orange.svg)](https://github.com/sumory/orange/releases/latest) [![license](https://img.shields.io/github/license/sumory/orange.svg)](https://github.com/sumory/orange/blob/master/LICENSE)


<a href="./README_zh.md" style="font-size:13px">中文</a> | <a href="./README.md" style="font-size:13px">English</a> | <a href="http://orange.sumory.com" style="font-size:13px">Website</a>

Orange是一个基于OpenResty的API网关。除Nginx的基本功能外，它还可用于API监控、访问控制(鉴权、WAF)、流量筛选、访问限速、AB测试、静/动态分流等。它有以下特性：

- 提供了一套默认的Dashboard用于动态管理各种功能和配置
- 提供了API接口用于实现第三方服务(如个性化运维需求、第三方Dashboard等)
- 可根据规范编写自定义插件扩展Orange功能


### 使用

#### 安装依赖

- OpenResty: 版本应在1.11.2+
    - Orange的监控插件需要统计HTTP的状态数据，所以编译OpenResty时需要添加`--with-http_stub_status_module`
- [Lor](https://github.com/sumory/lor)框架
    - 若使用的Orange版本低于v0.6.2则应安装lor v0.2.*版本
    - 若使用的Orange版本高于或等于v0.6.2则应安装lor v0.3.0+版本
- MySQL
    - 配置存储和集群扩展需要MySQL支持
- 安装luarocks和opm包管理工具
    - luarocks安装LuaRocks 2.2.2+以上版本。
    - 若使用openresty,自身集成opm工具，在openresty/bin目录下。
     
#### 数据表导入MySQL

- 在MySQL中创建数据库，名为orange
- 将与当前代码版本配套的SQL脚本(如install/orange-v0.7.0.sql)导入到orange库中

#### 修改配置文件

Orange有**两个**配置文件，一个是`conf/orange.conf`，用于配置插件、存储方式和内部集成的默认Dashboard，另一个是`conf/nginx.conf`用于配置Nginx.

orange.conf的配置如下，请按需修改:

```javascript
{
    "plugins": [ //可用的插件列表，若不需要可从中删除，系统将自动加载这些插件的开放API并在7777端口暴露
        "stat",
        "monitor",
        ".."
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
        }
    },

    "dashboard": {//默认的Dashboard配置.
        "auth": false, //设为true，则需用户名、密码才能登录Dashboard,默认的用户名和密码为admin/orange_admin
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

conf/nginx.conf里是一些nginx相关配置，请自行检查并按照实际需要更改或添加配置，特别注意以下几个配置：

- lua_package_path：需要根据本地环境配置适当修改，如[lor](https://github.com/sumory/lor)框架的安装路径
- resolver：DNS解析
- 各个server或是location的权限，如是否需要通过`allow/deny`指定配置黑白名单ip


#### 安装与配置

1) 安装依赖包
```
    cd orange
    luarocks install luafilesystem
    luarocks install luasocket
    luarocks install lrandom
    opm --install-dir=./ get zhangbao0325/orangelib        
```

2) 修改配置文件
```angular2html
    cd conf
    cp orange.conf.example orange.conf
    cp nginx.conf.example nginx.conf
    
```
其中，orange.conf中数据库store_mysql配置请修改成你安装好的数据库。
nginx.conf中lua_package_path添加上你的luarocks的lua包安装路径。


3) 脚本管理工具

无需安装, 只要将Orange下载下来, 根据需要修改一下`orange.conf`和`nginx.conf`配置，然后使用`start.sh`脚本即可启动。
默认提供的nginx.conf和start.sh都是最简单的配置，只是给用户一个默认的配置参考，用户应该根据实际生产要求自行添加或更改其中的配置以满足需要。

4) 命令行管理工具

可以通过`make install`将Orange安装到系统中(默认安装到/usr/local/orange)。 执行此命令后， 以下两部分将被安装：

```bash
# /usr/local/orange     // orange运行时需要的文件
# /usr/local/bin/orange // orange命令行工具
```

#### 启动

若采用方式一安装，则执行`sh start.sh`即可启动。可以按需要仿照start.sh编写运维脚本， 本质上就是启动/关闭Nginx。

若采用方式二`make install`安装，则可以通过命令行工具`orange`来管理， 执行`orange help`查看有哪些命令可以使用：

```
Usage: orange COMMAND [OPTIONS]

The commands are:

start   Start the Orange Gateway
stop    Stop current Orange
reload  Reload the config of Orange
restart Restart Orange
store   Init/Update/Backup Orange store
version Show the version of Orange
help    Show help tips
```

Orange启动成功后， dashboard和API server也随之启动：

- 内置的Dashboard可通过`http://localhost:9999`访问
- API Server默认在`7777`端口监听，如不需要API Server可删除nginx.conf里对应的配置

### 文档

- 项目文档: [官网](http://orange.sumory.com/docs)
- API文档: [开放API](./docs/api/README.md)


### Docker

[https://store.docker.com/community/images/syhily/orange](https://store.docker.com/community/images/syhily/orange) 由[@syhily](https://github.com/syhily)维护.

### 贡献者

- [@syhily](https://github.com/syhily)
- [@lhmwzy](https://github.com/lhmwzy)
- [@spacewander](https://github.com/spacewander)
- [@noname007](https://github.com/noname007)
- [@itchenyi](https://github.com/itchenyi)
- [@Near-Zhang](https://github.com/Near-Zhang)
- [@khlipeng](https://github.com/khlipeng)
- [@wujunze](https://github.com/wujunze)
- [@shuaijinchao](https://github.com/shuaijinchao)
- [@EasonFeng5870](https://github.com/EasonFeng5870)
- [@zhjwpku](https://github.com/zhjwpku)



### See also

Orange的插件设计参考自[Kong](https://github.com/Mashape/kong).

### License

[MIT](./LICENSE) License
