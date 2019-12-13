# Orange

 [![Build Status](https://travis-ci.org/orlabs/orange.svg?branch=master)](https://travis-ci.org/orlabs/orange) [![license](https://img.shields.io/github/license/orlabs/orange.svg)](https://github.com/orlabs/orange/blob/master/LICENSE)


<a href="./README_zh.md" style="font-size:13px">中文</a> | <a href="./README.md" style="font-size:13px">English</a> | <a href="http://orange.sumory.com" style="font-size:13px">Website</a>

`Orange` 是一个基于 `OpenResty` 的API网关。除 `Nginx` 的基本功能外，它还可用于`API监控`、`访问控制(鉴权、WAF)`、`流量筛选`、`访问限速`、`AB测试`、`静/动态分流` 等。它有以下特性：

- 提供了一套默认的 `Dashboard` 用于动态管理各种功能和配置。
- 提供了API接口用于实现第三方服务(如`个性化运维需求`、`第三方Dashboard`等)。
- 可根据规范编写自定义插件扩展 `Orange` 功能。


## 安装 & 使用

### 生产环境安装（不支持 macOS）

#### 1) 安装依赖项

我们推荐使用 `luarocks` 来安装 `Orange`，以减少由不同操作系统发行版本中的依赖项扩展引起的问题。

在不同的操作系统上安装 `Orange` 所必需的系统依赖（`openresty`、`resty-cli`、`luarocks`等），请参见：[依赖安装文档](docs/install-dependencies.md)。

#### 2) 安装 Lor Framework

查看`Lor Framework`[官方文档](https://github.com/sumory/lor)或执行以下命令。

```bash
git clone https://github.com/sumory/lor.git
cd lor
sudo make install
```

#### 3) 安装 Orange

```bash
curl -Lo install.sh https://raw.githubusercontent.com/orlabs/orange/master/install/install-orange.sh
sudo sh install.sh
```

安装过程结束后，输出消息 `orange 0.8-1 is now installed in /usr/local/orange/deps (license: MIT)` 即说明安装成功。

#### 4) 导入 MySQL

要求：`MySQL`版本 5.5+

 - 登录到 `MySQL` 客户端，创建一个 `orange` 数据库。
 
 - 导入数据表（`/usr/local/orange/conf/orange-v0.8.1.sql`）。
 
 - 修改`Orange`配位置文件中（`/usr/local/orange/conf/orange.conf`）`MySQL`相关配置。

#### 5) 启动 Orange

```bash
sudo orange start
```

`Orange` 启动成功后，`Dashboard` 和 `API server` 也随之启动：

 - 通过 `http://localhost:9999` 访问 `Dashboard`。
 - 通过 `http://localhost:7777` 访问 `API Server`。

至此，`Orange`已全部安装并配置完毕，请尽情享受。

### 开发环境安装（不支持 macOS）

#### 1) 依赖项和Lor

请使用 [生产环境安装](#生产环境安装不支持-macos) 方式中的 [安装依赖项](#1-安装依赖项) 和 [安装 Lor Framework](#2-安装-Lor-Framework) 方法进行安装。

#### 2) 安装 Orange

```bash
git clone https://github.com/orlabs/orange.git
cd orange
sudo make dev
```

安装过程结束后，输出消息 `Stopping after installing dependencies for orange-master 1.0-0` 即说明安装成功。

#### 3) 导入 MySQL

请使用 [生产环境安装](#生产环境安装不支持-macos) 方式中的 [导入 MySQL](#4-导入-MySQL) 方法进行导入。

注意：在开发模式下安装 `Orange`。

- `MySQL数据表` 文件和 `Orange配置` 文件位于当前项目的 `conf`文件夹中。

- 请导入 `master` 分支SQL文件（`/usr/local/orange/conf/orange-master.sql`）。

#### 4) 启动 Orange

```bash
sudo ./bin/orange start
```

成功启动 `Orange` 后的访问方式，请参考：[生产环境安装](#生产环境安装不支持-macos) 方式中的 [启动 Orange](#5-启动-Orange)。

### 使用

#### 命令行管理工具

通过命令行工具`orange`来管理， 执行`orange help`查看有哪些命令可以使用：

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

## 文档

- 项目文档: [官网](http://orange.sumory.com/docs)
- API文档: [开放API](./docs/api/README.md)


## Docker

[https://store.docker.com/community/images/syhily/orange](https://store.docker.com/community/images/syhily/orange) 由[@syhily](https://github.com/syhily)维护.

## 贡献者

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



## See also

`Orange`的插件设计参考自[Kong](https://github.com/Mashape/kong).

## License

[MIT](./LICENSE) License
