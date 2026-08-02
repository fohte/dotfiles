SHELL := bash

.PHONY: all install clean
all: install

install:
	./install-config config.toml ~/.codex/config.toml .config.toml.installed

clean:
	rm -f .config.toml.installed
