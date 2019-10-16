INST_PREFIX ?= /usr
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INST_BINDIR ?= /usr/bin
INSTALL ?= install
COPY ?= cp
LINK ?= ln
REMOVE ?= rm
CHMOD ?= chmod
UNAME ?= $(shell uname)
OR_EXEC ?= $(shell which openresty)
LUA_JIT_DIR ?= $(shell ${OR_EXEC} -V 2>&1 | grep prefix | grep -Eo 'prefix=(.*?)/nginx' | grep -Eo '/.*/')luajit
LUAROCKS_VER ?= $(shell luarocks --version | grep -E -o  "luarocks [0-9]+")


### help:         Show Makefile rules.
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'


### dev:          Create Orange development ENV
.PHONY: dev
dev:
ifeq ($(UNAME),Darwin)
	luarocks install --lua-dir=$(LUA_JIT_DIR) rockspec/orange-0.8-0.rockspec --tree=deps --only-deps --local
else ifneq ($(LUAROCKS_VER),'luarocks 3')
	luarocks install rockspec/orange-0.8-0.rockspec --tree=deps --only-deps --local
else
	luarocks install --lua-dir=/usr/local/openresty/luajit rockspec/orange-0.8-0.rockspec --tree=deps --only-deps --local
endif
	$(INSTALL) conf/nginx.conf.example conf/nginx.conf
	$(INSTALL) conf/orange.conf.example conf/orange.conf
	$(INSTALL) install/orange-v0.7.0.sql conf/orange-v0.7.0.sql


### install:      Install the Orange
.PHONY: install
install:
	$(INSTALL) -d /usr/local/orange/logs
	$(INSTALL) -d /usr/local/orange/conf
	$(INSTALL) -d /usr/local/orange/dashboard/views
	$(INSTALL) -d /usr/local/orange/dashboard/static

	$(INSTALL) conf/nginx.conf.example /usr/local/orange/conf/nginx.conf
	$(INSTALL) conf/orange.conf.example /usr/local/orange/conf/orange.conf
	$(INSTALL) conf/mime.types /usr/local/orange/conf/mime.types
	$(INSTALL) install/orange-v0.7.0.sql /usr/local/orange/conf/orange-v0.7.0.sql

	$(INSTALL) -d $(INST_LUADIR)/orange/dashboard
	$(INSTALL) -d $(INST_LUADIR)/orange/orange
	$(INSTALL) -d $(INST_LUADIR)/orange/bin

	$(COPY) -rf dashboard/* $(INST_LUADIR)/orange/dashboard
	$(COPY) -rf dashboard/views/* /usr/local/orange/dashboard/views
	$(COPY) -rf dashboard/static/* /usr/local/orange/dashboard/static
	$(COPY) -rf orange/* $(INST_LUADIR)/orange/orange
	$(COPY) -rf bin/* $(INST_LUADIR)/orange/bin

	$(INSTALL) bin/orange $(INST_BINDIR)/orange
	$(REMOVE) -f /usr/local/bin/orange
	$(LINK) -s $(INST_BINDIR)/orange /usr/local/bin/orange
