# Install Dependencies

* [CentOS 7](#centos-7)
* [Ubuntu 18](#ubuntu-18)

CentOS 7
========

```shell
# install epel, `luarocks` need it.
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ivh epel-release-latest-7.noarch.rpm

# add openresty source
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

# install openresty and some compilation tools
sudo yum install -y openresty openresty-resty curl git automake autoconf \
    gcc pcre-devel openssl-devel libtool gcc-c++ luarocks cmake3 lua-devel

sudo ln -s /usr/bin/cmake3 /usr/bin/cmake
```

Ubuntu 18
==========

```shell
# add openresty source
wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
sudo apt-get update

# install openresty and some compilation tools
sudo apt-get install -y openresty openresty-resty curl git luarocks\
    check libpcre3 libpcre3-dev libjemalloc-dev \
    libjemalloc1 build-essential libtool libssl1.0-dev automake autoconf pkg-config cmake
```
