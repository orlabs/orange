VERSION = 0.5.0

TO_INSTALL = api bin conf dashboard orange
ORANGE_HOME ?= /usr/local/orange/
ORANGE_BIN ?= /usr/local/bin/orange

.PHONY: test install show

test:
	@echo "to be continued..."

install:
	@rm -rf $(ORANGE_BIN)
	@rm -rf $(ORANGE_HOME)
	@mkdir -p $(ORANGE_HOME)

	@for item in $(TO_INSTALL) ; do \
		cp -a $$item $(ORANGE_HOME); \
	done;

	@echo "#!/usr/bin/env resty" >> $(ORANGE_BIN)
	@echo "package.path=\"$(ORANGE_HOME)?.lua;;\"" >> $(ORANGE_BIN)
	@echo "require(\"bin.main\")(arg)" >> $(ORANGE_BIN)
	@chmod +x $(ORANGE_BIN)
	@echo "Orange installed."
	@orange help

show:
	@orange help
