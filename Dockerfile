FROM centos:7
WORKDIR /opt/orange
ENV LC_ALL zh_CN.utf8
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum install -y wget \
    # install epel, `luarocks` need it.
    && wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm -ivh epel-release-latest-7.noarch.rpm \
    # add openresty source
    && yum install -y yum-utils \
    && yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo \
    # install openresty and some compilation tools
    && yum install -y openresty openresty-resty curl git make automake autoconf gcc pcre-devel openssl-devel libtool gcc-c++ luarocks cmake3 lua-devel git \
    && git clone https://gitee.com/dkdnet/lor.git \
    && cd lor \
    && make install \
    && ln -s /usr/bin/cmake3 /usr/bin/cmake \
    && yum -y install kde-l10n-Chinese \
    && yum -y reinstall glibc-common \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
EXPOSE 9999 80 7777
COPY . .
CMD make dev && make install && resty bin/orange start && tail -f /opt/orange/logs/access.log
