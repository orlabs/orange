# Orange

 [![GitHub release](https://img.shields.io/github/release/sumory/orange.svg)](https://github.com/sumory/orange/releases/latest) [![license](https://img.shields.io/github/license/sumory/orange.svg)](https://github.com/sumory/orange/blob/master/LICENSE)

<a href="./README_zh.md" style="font-size:13px">中文</a> | <a href="./README.md" style="font-size:13px">English</a> | <a href="http://orange.sumory.com" style="font-size:13px">Website</a>


A Gateway based on OpenResty(Nginx + Lua) for API Monitoring and Management.


## Install & Usages

### Install of Production Environment (Not Support macOS)

#### 1) Install Dependencies
We recommend that you use [luarocks](https://luarocks.org/) to install `Orange` to reduce problems caused by dependency extensions in different operating system releases.

System dependencies (`openresty`, `resty-cli`, `luarocks`, etc.) necessary to install `Orange` on different operating systems, See: [Install Dependencies](docs/install-dependencies.md) Document.

#### 2) Install Lor Framework

Check the [official documentation](https://github.com/sumory/lor) for `Lor Framework` or execute the following command.

```bash
git clone https://github.com/sumory/lor.git
cd lor
sudo make install
```

#### 3) Install Orange

```bash
curl -Lo install.sh https://raw.githubusercontent.com/orlabs/orange/master/install/install-orange.sh
sudo sh install.sh
```

After the installation process is completed, the output message `orange 0.8-0 is now installed in /usr/local/orange/deps (license: MIT)` indicates that the installation was successful.

#### 4) Import MySQL

Requirements: MySQL Version 5.5+

 - Login to the `MySQL` client, create an `orange` database.
 
 - Import the data table (`/usr/local/orange/conf/orange-v0.8.0.sql`).
 
 - Modify the `Orange` configuration file (`/usr/local/orange/conf/orange.conf`) `MySQL` related configuration.

#### 5) Start Orange

```bash
sudo orange start
```

After the `Orange` launches successfully, the `dashboard` and `API Server` are started:

 - Access `Dashboard` via `http://localhost:9999`.
 - Access `API Server` via `http://localhost:7777`.

At this point, `Orange` has all been installed and configured, please enjoy it.

### Install of Development Environment (Not Support macOS)

#### 1) Dependencies and Lor

Please use the [Install Dependencies](#1-install-dependencies) and [Install Lor Framework](#2-install-lor-framework) methods in [Install of Production Environment](#install-of-production-environment-not-support-macos) to install.

#### 2) Install Orange

```bash
git clone https://github.com/orlabs/orange.git
cd orange
sodu make dev
```

After the installation process is completed, the output message `Stopping after installing dependencies for orange-master 1.0-0` indicates that the installation was successful.

#### 3) Import MySQL

Please use the [Import MySQL](#4-import-mysql) methods in [Install of Production Environment](#install-of-production-environment-not-support-macos) to import.

Note: Install `Orange` in `Development Environment`, the `MySQL Data Table` file and the `Orange Config` file are located in the `conf` folder of the current project.

#### 4) Start Orange

```bash
sudo ./bin/orange start
```

Access method after the successful startup of `Orange`, please refer to: [Start Orange](#5-start-orange) in [Install of Production Environment](#install-of-production-environment-not-support-macos).


### Usages

#### CLI tools

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


## Documents

Find more about `Orange` on its [website](http://orange.sumory.com/docs). There is only a Chinese version for now.


## Docker

[https://store.docker.com/community/images/syhily/orange](https://store.docker.com/community/images/syhily/orange) maintained by [@syhily](https://github.com/syhily)


## Contributors

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

The plugin architecture is highly inspired by [Kong](https://github.com/Mashape/kong).


## License

[MIT](./LICENSE)
