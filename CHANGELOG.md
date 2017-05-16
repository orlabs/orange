### v0.6.4 2017.05.16

- 修复issue#110, 解决在添加/删除规则后本地js cache未更新，之后立刻更改选择器配置造成的规则丢失bug
- 修改Makefile， 支持自定义安装路径
    - 自定义安装后，orange命令须手动添加到环境变量
    - 使用诸如start命令时需指定--prefix
- 为github issue添加默认模板
- 默认的配置文件添加了一些log项
- 修复了原来pr里的一些拼写问题
- 移除docs/api里的文档， 更多文档请到[官网](http://orange.sumory.com)查看

### v0.6.3 2017.03.10

- 添加插件： `signature auth plugin`
- 将默认的配置文件做成模板，即`ngingx.conf.example`和`orange.conf.example`

### v0.6.2 2017.02.18

- 兼容Orange与最新版本的[lor]（https://github.com/sumory/lor）, 即lor v0.3.0

注意：

- 若使用的Orange版本在0.6.2以下，则应安装lor v0.2.*版本, 推荐lor v0.2.6
- 若使用的Orange版本在0.6.2及以上，可升级lor到v0.3.0+版本

### v0.6.1 2017.02.09

添加property based rate limiting插件，该插件由[@noname007](https://github.com/noname007)贡献

### v0.6.0 2016.11.13

注意，0.6.*版本与之前的版本并不兼容，主要改动如下：

- 重构Dashboard
- 新增kvstore插件： 用于通过API存取shared dict数据
- 重构“规则”设计： 流量筛选时改为分层结构， 通过“选择器”对规则分组
- 提取插件API公共代码统一维护

### v0.5.1 2016.11.10

- 修复一个sql bug

### v0.5.0 2016.10.04

- 添加`Makefile`安装方式
- 支持通过命令行`orange store`初始化数据库
- 添加resty-cli支持
    - 支持orange start/stop/restart/reload/store等命令
- Break Change: 将*.conf配置移动到conf目录下


### v0.4.0 2016.09.24

- [x] 删除examples
- [x] 添加key auth插件
- [x] 限流插件rate limiting
- [ ] 防重提交机制（delay）
- [x] 补全新插件API文档

### v0.3.0 2016.07.21

- 添加HTTP Basic Auth插件

### v0.2.0

- API Server支持HTTP Basic Authorization
- 变量提取模块增加新类型
	- URL提取器支持一次提取多值
	- 以模板方式使用变量，格式为{{extractor.key}}
- 去除file store支持
- 提供Restful API及详细描述文档
- 分离内置的Dashboard，减少与API的耦合

### v0.1.1 2016.05.09

- 在使用MySQL作为存储时，为dashboard控制台添加账户系统


### v0.1.0 2016.05.04

特性:

- 配置项支持文件存储和MySQL存储
- 通过MySQL存储来简单支持集群部署
- 支持通过自定义插件方式扩展功能
- 默认内置六个插件
	- 全局状态统计
	- 自定义监控
	- URL重写
	- URI重定向
	- 简单防火墙
	- 代理、ABTesting、分流
- 提供管理界面用于管理内置插件

### v0.0.2

 - 完成监控、redirect/rewrite、WAF、分流等几个插件
 - 仍不推荐生产使用
