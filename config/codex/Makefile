SHELL := bash

.PHONY: all install clean
all: install

install:
	./install-config config.toml ~/.codex/config.toml .config.toml.installed
	./install-hooks ~/.codex/hooks.json
# Only a convenience; a Codex protocol change must not block the rest of the deploy.
	-./trust-hooks

clean:
	rm -f .config.toml.installed
