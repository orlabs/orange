TO_INSTALL = api bin conf dashboard orange install
DEV_ROCKS = "lua-resty-http 0.13-0" "lua-resty-kafka 0.06-0" "lua-resty-dns-client 1.0.0-1" "lua-resty-jwt 0.2.0-0" "luasocket 3.0rc1-2"
ORANGE_HOME ?= /usr/local/orange
ORANGE_BIN ?= /usr/local/bin/orange
ORNAGE_HOME_PATH = $(subst /,\\/,$(ORANGE_HOME))

.PHONY: test install show dependencies init-config
init-config:
	@ test -f conf/nginx.conf   || (cp conf/nginx.conf.example conf/nginx.conf && echo "copy nginx.conf")
	@ test -f conf/orange.conf  || (cp conf/orange.conf.example conf/orange.conf && echo "copy orange.conf")

dependencies:
	@for rock in $(DEV_ROCKS) ; do \
	  if luarocks list --porcelain $$rock | grep -q "installed" ; then \
	    echo $$rock already installed, skipping ; \
	  else \
	    echo $$rock not found, installing via luarocks... ; \
	    luarocks install $$rock >> /dev/null ; \
	  fi \
	done;

test:
	@echo "to be continued..."

install:init-config
	@rm -rf $(ORANGE_BIN)
	@rm -rf $(ORANGE_HOME)
	@mkdir -p $(ORANGE_HOME)

	@for item in $(TO_INSTALL) ; do \
		cp -a $$item $(ORANGE_HOME)/; \
	done;

	@cat $(ORANGE_HOME)/conf/nginx.conf | sed "s/..\/?.lua;\/usr\/local\/lor\/?.lua;;/"$(ORNAGE_HOME_PATH)"\/?.lua;\/usr\/local\/lor\/?.lua;;/" > $(ORANGE_HOME)/conf/new_nginx.conf
	@rm $(ORANGE_HOME)/conf/nginx.conf
	@mv $(ORANGE_HOME)/conf/new_nginx.conf $(ORANGE_HOME)/conf/nginx.conf

	@echo "#!/usr/bin/env resty" >> $(ORANGE_BIN)
	@echo "package.path=\"$(ORANGE_HOME)/?.lua;;\" .. package.path" >> $(ORANGE_BIN)
	@echo "require(\"bin.main\")(arg)" >> $(ORANGE_BIN)
	@chmod +x $(ORANGE_BIN)
	@echo "Orange installed."
	$(ORANGE_BIN) help

show:
	$(ORANGE_BIN) help
