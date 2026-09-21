SHELL := bash

include ../mcp/dependencies.mk

.PHONY: all install clean
all: install

config.toml: config.base.toml build-config $(MCP_INPUTS)
	./build-config config.base.toml $@

install: config.toml
	./install-config config.toml ~/.codex/config.toml .config.toml.installed
	./install-hooks ~/.codex/hooks.json
# Only a convenience; a Codex protocol change must not block the rest of the deploy.
	-./trust-hooks

clean:
	rm -f config.toml .config.toml.installed
