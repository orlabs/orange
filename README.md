# Orange

<a href="./README_zh.md" style="font-size:13px">中文</a> | <a href="./README.md" style="font-size:13px">English</a> | <a href="http://orange.sumory.com" style="font-size:13px">Website</a>


A Gateway based on OpenResty(Nginx+lua) for API Monitoring and Management.


### Install & Usages

#### Requirements

- MySQL v5.5+
- OpenResty v1.9.7.3+ or Nginx+lua module
    - install OpenResty with `--with-http_stub_status_module` option
- [Lor Framework](https://github.com/sumory) v0.2.5+
- libuuid.so

Import the SQL file(e.g. install/orange-v0.6.0.sql) which is adapted to your Orange version to MySQL database named `orange`.

#### Install

**1) version < 0.5.0**

If you use Orange under v0.5.0, there is no need to `install`.

**2) version >= 0.5.0**

In addition to `start.sh` script, a new cli tool could be utilized to manage Orange. You should install the cli first:

```
cd orange
make install
```

then, the Orange runtime lua module is installed in `/usr/local/orange` and an executable command named `/usr/local/bin/orange` is generated.


#### Usages

Before starting Orange, you should ensure that the `orange.conf` and `nginx.conf` are redefined to satisfy the demands of your project.


**1) version < 0.5.0**

Just `sh start.sh` to start Orange. You could rewrite some other shell scripts as you need.

**2) version >= 0.5.0**

`orange help` to check usages:

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


### Documents

Find more about Orange on its [website](http://orange.sumory.com/docs). There is only a Chinese version for now.


### Docker

[http://hub.docker.com/r/syhily/orange](http://hub.docker.com/r/syhily/orange) maintained by [@syhily](https://github.com/syhily)


### Contributors

- 雨帆([@syhily](https://github.com/syhily))
- lhmwzy([@lhmwzy](https://github.com/lhmwzy))


### See also

The plugin architecture is highly inspired by [Kong](https://github.com/Mashape/kong).


### License

[MIT](./LICENSE)
