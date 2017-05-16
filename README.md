# Orange

 [![GitHub release](https://img.shields.io/github/release/sumory/orange.svg)](https://github.com/sumory/orange/releases/latest) [![license](https://img.shields.io/github/license/sumory/orange.svg)](https://github.com/sumory/orange/blob/master/LICENSE)

<a href="./README_zh.md" style="font-size:13px">中文</a> | <a href="./README.md" style="font-size:13px">English</a> | <a href="http://orange.sumory.com" style="font-size:13px">Website</a>


A Gateway based on OpenResty(Nginx+lua) for API Monitoring and Management.


### Install & Usages

#### Requirements

- MySQL v5.5+
- OpenResty v1.9.7.3+ or Nginx+lua module
    - install OpenResty with `--with-http_stub_status_module` option
- [Lor Framework](https://github.com/sumory/lor) please mind:
    - Orange v0.6.1 and versions before v0.6.1 are compatible with lor v0.2.*
    - Orange v0.6.2+ is compatible with lor v0.3.0+

Import the SQL file(e.g. install/orange-v0.6.3.sql) which is adapted to your Orange version into MySQL database named `orange`.

#### Install

1) script management

use shell scripts (e.g. `start.sh`) to manage Orange.

2) CLI tool

In addition to `start.sh` script, a new cli tool could be utilized to manage Orange. You should install the cli first:

```
cd orange
make install
```

then, the Orange runtime lua module is installed in `/usr/local/orange` and an executable command named `/usr/local/bin/orange` is generated.

#### Usages

Before starting Orange, you should ensure that the `orange.conf` and `nginx.conf` are redefined to satisfy the demands of your project.

1) script management

Just `sh start.sh` to start Orange. You could rewrite some other shell scripts as you need.

2) CLI tool

`orange help` to check usages:

```shell
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


### Documents

Find more about Orange on its [website](http://orange.sumory.com/docs). There is only a Chinese version for now.


### Docker

[https://store.docker.com/community/images/syhily/orange](https://store.docker.com/community/images/syhily/orange) maintained by [@syhily](https://github.com/syhily)


### Contributors

- [@syhily](https://github.com/syhily)
- [@lhmwzy](https://github.com/lhmwzy)
- [@spacewander](https://github.com/spacewander)
- [@noname007](https://github.com/noname007)
- [@itchenyi](https://github.com/itchenyi)

### See also

The plugin architecture is highly inspired by [Kong](https://github.com/Mashape/kong).


### License

[MIT](./LICENSE)
