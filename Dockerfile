FROM centos:7
WORKDIR /opt/orange
EXPOSE 80 7777 8888 9999
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum update -y \
    && yum install -y wget \
    # install epel, `luarocks` need it.
    && wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm -ivh epel-release-latest-7.noarch.rpm \
    # install some compilation tools
    && yum install -y yum-utils git libuuid-devel pcre-devel openssl-devel gcc gcc-c++ make perl-Digest-MD5 lua-devel cmake3 curl libtool autoconf automake openresty-resty readline-devel unzip gettext kde-l10n-Chinese which net-tools swig \
    && yum -y reinstall glibc-common \
    && ln -s /usr/bin/cmake3 /usr/bin/cmake \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
ENV LC_ALL zh_CN.utf8
RUN cd /usr/local/src \
    && git clone https://gitee.com/xiaowu_wang/lor.git \
    # install lor
    && cd lor \
    && make install
RUN cd /usr/local/src \
    && git clone https://gitee.com/xiaowu_wang/libinjection.git \
    # compile libinjection
    && cd libinjection/lua \
    && make \
    && mkdir -p /opt/orange/deps/lib64/lua/5.1/ \
    && cp libinjection.so /opt/orange/deps/lib64/lua/5.1/
RUN mkdir -p /usr/local/nginx/conf \
    # download ngx waf
    && cd /usr/local/nginx/conf \
    && git clone https://gitee.com/xiaowu_wang/ngx_lua_waf.git --branch v0.7.2-orange --single-branch \
    && mv ngx_lua_waf waf
RUN cd /usr/local/src \
    # install luarocks
    && git clone https://gitee.com/xiaowu_wang/luarocks.git --branch v3.9.2 --single-branch \
    && cd luarocks \
    && ./configure --prefix=/usr/local/luarocks --with-lua=/usr --with-lua-include=/usr/include \
    && make \
    && make install \
    && ln -s /usr/local/luarocks/bin/luarocks /usr/local/bin/luarocks
RUN cd /usr/local/src \
    # install openresty and compile
    && wget https://openresty.org/download/openresty-1.21.4.1.tar.gz \
    && wget https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/08a395c66e42.zip -O ./nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip \
    && tar -xzvf openresty-1.21.4.1.tar.gz \
    && unzip -D nginx-goodies-nginx-sticky-module-ng-08a395c66e42.zip \
    && mv nginx-goodies-nginx-sticky-module-ng-08a395c66e42 openresty-1.21.4.1/nginx-sticky-module-ng \
    && cd openresty-1.21.4.1 \
    && ./configure --prefix=/usr/local/openresty --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-http_realip_module --add-module=./nginx-sticky-module-ng \
    && make \
    && make install \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx \
    && ln -s /usr/local/openresty/bin/openresty /usr/bin/openresty \
    && ln -s /usr/local/openresty/bin/resty /usr/bin/resty \
    && ln -s /usr/local/openresty/bin/opm /usr/bin/opm \
    && openresty
# 提前构建
COPY rockspec ./rockspec/
COPY Makefile ./Makefile
RUN make dependency
COPY . .
CMD make dev && make install && sleep 5 && resty bin/orange start && tail -f /opt/orange/logs/access.log
