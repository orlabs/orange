## 0.8.1
> Released on 2019.12.12

#### 新功能

- 集成自动化构建平台（Travis CI）。
- 增加基础测试框架（Test::Nginx）。
- 为 `headers` 插件添加测试用例。
- 为 `redirect` 插件添加测试用例。
- 为 `rewrite` 插件添加测试用例。
- 为 `basic_auth` 插件添加测试用例。
- 为 `key_auth` 插件添加测试用例。
- 为 `jwt_auth` 插件添加测试用例。
- 为 `signature_auth` 插件添加测试用例。
- 为 `rate_limiting` 插件添加测试用例。
- 为 `waf` 插件添加测试用例。
- 为 `divide` 插件添加测试用例。

#### 修复

- `luarocks` 安装 `api` 目录不存在问题。

#### 变更

- `lua-resty-consul` 依赖库由项目中存储改为使用 `luarocks` 安装。
- `nginx.conf` 默认日志级别，由 `info` 调整为 `error`。
- `balancer`  插件由于与现有功能冲突，迁移至 `v0.9.0-dev`。
- `dynamic_upstream`  插件由于与现有功能冲突，迁移至 `v0.9.0-dev`。
- `consul_balancer` 插件由于与现有功能冲突，迁移至 `v0.9.0-dev`。
- `persist` 插件由于与现有功能冲突，迁移至 `v0.9.0-dev`。

#### 文档

- 为 `headers` 插件添加使用文档。
- 为 `redirect` 插件添加使用文档。
- 为 `rewrite` 插件添加使用文档。
- 为 `basic_auth` 插件添加使用文档
- 为 `key_auth` 插件添加使用文档。
- 为 `jwt_auth` 插件添加使用文档。
- 为 `signature_auth` 插件添加使用文档。
- 为 `rate_limiting` 插件添加使用文档。
- 为 `waf` 插件添加使用文档。
- 为 `divide` 插件添加使用文档。
- 为 `global_statistics` 插件添加使用文档。


## 0.8.0 
> Released on 2019.10.18

#### 新功能

- 依赖安装方式由 `opm` 改为使用 `luarocks` 进行依赖安装和环境部署。


## 0.7.1 
> Released on 2019.07.09

#### 新功能

- 使用 `opm` 方式进行 `Orange` 的依赖安装。

#### 修复

- 修复 `Makefile` 安装项目依赖问题。
- 修复模板变量获取问题。
- 修复 `divide` 分流插件加args后 `balancer` 无法读取的问题。


## 0.7.0 
> Released on 2019.04.01

#### 新功能

- 支持通过`cookie`、`随机数`、`HTTP Method`进行请求拦截过滤。
- 新增取余的方式进行规则匹配。
- 新增 `kafka` 插件。
- 新增 `balancer` 插件。
- 新增 `consul_balancer` 插件。
- 新增 `persist log` 插件。
- 新增 `node` 插件。

#### 修复

- 修复后台页面展示异常问题。
- 修复 `balancer` 开关未打开时出现 `invalid URL prefix in ""` 的错误。
- 修复选择器类型为 `1` 时 `continue=false` 的错误。
- 修复 `proxy read timeout` 配置无效的问题。
- 修复忽略大小写进行匹配鉴权值的问题。

#### 变更

- 对 `balancer` 模块的管理后台代码和文档说明规则重构。
- 更新 `Makefile`，对依赖进行版本指定。


## 0.6.4 
> Released on 2017.05.16

#### 新功能

- 为 `github issue` 添加默认模板。
- 默认的配置文件添加 `log` 项。

#### 修复

- 修复了在添加和删除规则后本地 `JavaScript Cache` 未更新导致选择器配置规则丢失问题。
- 修复了`PR`中的拼写问题。

#### 变更

- 修改Makefile，支持自定义安装路径。
- 移除 `docs/api` 中的文档，更多文档请到[官网](http://orange.sumory.com)查看。


## 0.6.3
> Released on 2017.03.10

#### 新功能

- 新增 `signature auth` 插件。
- 新增默认配置文件模板 `ngingx.conf.example` 和 `orange.conf.example`。


## 0.6.2 
> Released on 2017.02.18

#### 新功能

- 兼容 `Orange` 与最新版本的 `Lor Framework`，即lor v0.3.0。

#### 注意

- 若使用的 `Orange` 版本在 `0.6.2` 以下，则应安装 `lor v0.2.x` 版本, 推荐 `lor v0.2.6`。
- 若使用的 `Orange` 版本在 `0.6.2` 及以上，可升级 `lor v0.3.0+` 版本。


## 0.6.1 
> Released on 2017.02.09

#### 新功能

- 新增 `property based rate limiting` 插件。


## 0.6.0 
> Released on 2016.11.13

#### 新功能

- 重构 `Dashboard`。
- 新增 `kvstore` 插件，用于通过API存取 `shared dict` 数据。
- 重构规则设计，流量筛选时改为分层结构，通过 `选择器` 对规则分组。
- 提取插件API公共代码，统一维护。

#### 注意

- `Orange 0.6.*` 版本与之前的版本并不兼容。


## 0.5.1
> Released on 2016.11.10

#### 修复

- 修复SQL导入问题。


## 0.5.0 
> Released on 2016.10.04

#### 新功能

- 添加`Makefile`安装方式。
- 支持通过命令行 `orange store` 初始化数据库。
- 添加 `resty-cli` 支持，命令 `orange [start | stop | restart | reload | store]`。

#### 变更

- 将 `*.conf` 配置移至 `conf` 目录下。


## 0.4.0 
> Released on 2016.09.24

#### 新功能

- 新增 `rate limiting` 限流插件。
- 新增防重提交机制（delay）。
- 新增 `key auth` 插件。

#### 变更

- 移除 `examples`。


## 0.3.0 
> Released on 2016.07.21

#### 新功能

- 新增 `Basic Auth` 插件。


## 0.2.0
> Released on 2016.07.15

#### 新功能

- `API Server`支持`HTTP Basic Authorization`。
- 变量提取模块增加新类型，`URL` 提取器支持一次提取多值。模板方式使用变量，格式为 `{{extractor.key}}`。
- 提供 `Restful API` 及详细描述文档。
- 分离内置 `Dashboard`，减少与API的耦合。

#### 变更

- 去除 `file store` 支持。


## 0.1.1 
> Released on 2016.05.09

#### 新功能

- 使用 `MySQL` 作为存储时，为 `Dashboard` 添加用户系统。


## 0.1.0 
> Released on 2016.05.04

#### 新功能

- 配置项支持 `文件` 和 `MySQL` 存储。
- 通过 `MySQL` 存储来简单支持集群部署。
- 支持通过自定义插件方式扩展功能。
- 新增 `Global statistics`，全局状态统计插件。
- 新增 `Custom monitoring`，自定义监控插件。
- 新增 `URL Rewiter`，URL重写插件。
- 新增 `URL Redirect`，URI重定向插件。
- 新增 `WAF`，防火墙插件。
- 新增 `ABTesting`，分流插件。
- 提供管理界面用于管理内置插件。
