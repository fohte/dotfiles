SHELL := bash

SETTINGS := $(HOME)/.gemini/antigravity-cli/settings.json

.PHONY: all
all: install

# agy owns settings.json: it appends trustedWorkspaces as workspaces are trusted,
# and it replaces the file instead of writing through it, so a symlink placed here
# is silently swapped back to a regular file. Merge in only the keys this repo
# owns and leave agy's runtime state alone.
.PHONY: install
install: settings.json
	@mkdir -p $(dir $(SETTINGS))
	@[ -f $(SETTINGS) ] || echo '{}' > $(SETTINGS)
	jq --slurpfile desired settings.json '. * $$desired[0]' $(SETTINGS) > $(SETTINGS).tmp
	@chmod 600 $(SETTINGS).tmp
	mv $(SETTINGS).tmp $(SETTINGS)
