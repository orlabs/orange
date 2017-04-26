TO_INSTALL = api bin conf dashboard orange install
ORANGE_HOME ?= /usr/local/orange
ORANGE_BIN ?= /usr/local/bin/orange

.PHONY: test install show
init-config:
	@ test -f conf/nginx.conf   || (cp conf/nginx.conf.example conf/nginx.conf && echo "copy nginx.conf")
	@ test -f conf/orange.conf  || (cp conf/orange.conf.example conf/orange.conf && echo "copy orange.conf")


deps:init-config
	mkdir -p resty
	unzip master.zip
	yes|cp -fr   lua-resty-http-master/lib/resty/*  resty/
	rm -fr  master.zip  lua-resty-http-master

test:
	@echo "to be continued..."

install:init-config
	@rm -rf $(ORANGE_BIN)
	@rm -rf $(ORANGE_HOME)
	@mkdir -p $(ORANGE_HOME)

	@for item in $(TO_INSTALL) ; do \
		cp -a $$item $(ORANGE_HOME)/; \
	done;

	@cat $(ORANGE_HOME)/conf/nginx.conf | sed "s/..\/\?.lua;\/usr\/local\/lor\/\?.lua;;/\/usr\/local\/orange\/\?.lua;\/usr\/local\/lor\/?.lua;;/" > $(ORANGE_HOME)/conf/new_nginx.conf
	@rm $(ORANGE_HOME)/conf/nginx.conf
	@mv $(ORANGE_HOME)/conf/new_nginx.conf $(ORANGE_HOME)/conf/nginx.conf

	@echo "#!/usr/bin/env resty" >> $(ORANGE_BIN)
	@echo "package.path=\"$(ORANGE_HOME)/?.lua;;\" .. package.path" >> $(ORANGE_BIN)
	@echo "require(\"bin.main\")(arg)" >> $(ORANGE_BIN)
	@chmod +x $(ORANGE_BIN)
	@echo "Orange installed."
	@orange help

show:
	@orange help
