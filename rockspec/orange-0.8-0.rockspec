package = "orange"
version = "0.8-0"
supported_platforms = {"linux"}

source = {
    url = "git://github.com/orlabs/orange",
    branch = "v0.8.0",
}

description = {
    summary = "Orange is OpenResty/Nginx Gateway for API Monitoring and Management.",
    homepage = "https://github.com/orlabs/orange",
    license = "MIT",
    maintainer = "JinChao Shuai <shuaijinchao@gmail.com>"
}

dependencies = {
    "luafilesystem = 1.7.0-2",
    "penlight = 1.5.4-1",
    "lrandom = 20180729-1",
    "luacrypto = 0.3.2-2",
    "luasocket = 3.0rc1-2",
    "lua-resty-http = 0.13-0",
    "lua-resty-kafka = 0.06-0",
    "lua-resty-dns-client = 1.0.0-1",
    "lua-resty-jwt = 0.2.0-0",
}

build = {
    type = "make",
    build_variables = {
        CFLAGS="$(CFLAGS)",
        LIBFLAG="$(LIBFLAG)",
        LUA_LIBDIR="$(LUA_LIBDIR)",
        LUA_BINDIR="$(LUA_BINDIR)",
        LUA_INCDIR="$(LUA_INCDIR)",
        LUA="$(LUA)",
    },
    install_variables = {
        INST_PREFIX="$(PREFIX)",
        INST_BINDIR="$(BINDIR)",
        INST_LIBDIR="$(LIBDIR)",
        INST_LUADIR="$(LUADIR)",
        INST_CONFDIR="$(CONFDIR)",
    },
}
