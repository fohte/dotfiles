SHELL := bash

# iconv: macOS returns NFD paths (e.g. "フ" + "゚") but Claude Code normalizes file_path to NFC
# internally while leaving permission patterns as-is, so patterns must also be NFC.
export OBSIDIAN_VAULT_PATH := $(shell obsidian vault name=obsidian-v2 info=path | iconv -f UTF-8-MAC -t UTF-8 | sed "s|^$$HOME|~|")

# Build a jsonnet file, merging role and local overlays if they exist.
# Layers (each can use +: syntax for deep merging, e.g. permissions+: { allow+: [...] }):
#   1. base (the .jsonnet file passed as argument)
#   2. role overlay (resolved via `dot role overlay`):
#      - private: <DOTFILES_DIR>/config/claude/<file>.private.jsonnet
#      - work:    ~/ghq/github.com/<repo>/config-overlays/claude/<file>.jsonnet
#   3. local overlay: <file>.local.jsonnet (gitignored, for secrets/machine-only tweaks)
# External variables referenced via env('VAR_NAME') are auto-detected from all layers
# and passed as --ext-str flags (jsonnet reads them from environment variables).
# usage: $(call jsonnet,<base.jsonnet>)
define jsonnet
$(strip \
	role_overlay=$$(dot role overlay $(CURDIR)/$(1) 2>/dev/null || true); \
	local_overlay=$(wildcard $(basename $(1)).local.jsonnet); \
	import_expr='(import "$(1)")'; \
	[ -n "$$role_overlay" ] && import_expr="$$import_expr"' + (import "'"$$role_overlay"'")'; \
	[ -n "$$local_overlay" ] && import_expr="$$import_expr"' + (import "'"$$local_overlay"'")'; \
	mise x -- jsonnet \
		$$(grep -oh "env('[^']*')" $(1) $$role_overlay $$local_overlay 2>/dev/null \
			| sort -u | sed "s/env('\\(.*\\)')/--ext-str \\1/") \
		-e "$$import_expr" \
)
endef

BUILD_TARGETS := settings.json mcp-servers.json

.PHONY: all
all: $(BUILD_TARGETS) install

settings.json: settings.jsonnet $(wildcard settings.local.jsonnet)
	$(call jsonnet,settings.jsonnet) | jq . > $@.tmp && mv $@.tmp $@

mcp-servers.json: mcp-servers.jsonnet $(wildcard mcp-servers.local.jsonnet)
	$(call jsonnet,mcp-servers.jsonnet) | jq . > $@.tmp && mv $@.tmp $@

# Detect if ~/.claude/settings.json has untracked drift (like terraform detecting drift).
# Three-way comparison using .settings.json.installed (state), settings.json (desired),
# and ~/.claude/settings.json (actual).
# Drift = paths where actual differs from state. Drift is allowed if every drifted
# path is already reflected in desired (i.e. desired matches actual at that path).
# Detected by: diff(actual, state) ∖ diff(actual, desired) — paths drifted from state
# but not yet adopted in desired.
.PHONY: check-settings
check-settings: settings.json
	@if [ -f ~/.claude/settings.json ] && [ -f .settings.json.installed ]; then \
		undadopted=$$(jq -n \
			--slurpfile state .settings.json.installed \
			--slurpfile actual ~/.claude/settings.json \
			--slurpfile desired settings.json \
			'def all_paths: [paths] + [[]] | unique; \
			 ($$state[0]) as $$s | ($$actual[0]) as $$a | ($$desired[0]) as $$d | \
			 (($$s | all_paths) + ($$a | all_paths)) | unique | \
			 map(select((($$s | getpath(.)?) != ($$a | getpath(.)?)) and (($$d | getpath(.)?) != ($$a | getpath(.)?))))'); \
		if [ "$$undadopted" != "[]" ]; then \
			echo "error: ~/.claude/settings.json has changes not reflected in jsonnet." >&2; \
			echo "" >&2; \
			echo "Drifted paths not adopted in settings.jsonnet:" >&2; \
			echo "$$undadopted" | jq . >&2; \
			echo "" >&2; \
			echo "--- settings.json (built from jsonnet)" >&2; \
			echo "+++ ~/.claude/settings.json (actual)" >&2; \
			diff <(jq -S . settings.json) <(jq -S . ~/.claude/settings.json) >&2 || true; \
			echo "" >&2; \
			echo "Reflect the changes in settings.jsonnet to adopt the drift." >&2; \
			exit 1; \
		fi; \
	fi

# Install built files into their destinations.
# Separated from build to avoid corrupting target files if jsonnet fails.
.PHONY: install
install: $(BUILD_TARGETS) check-settings
	cp settings.json ~/.claude/settings.json
	cp settings.json .settings.json.installed
	jq --argjson mcp "$$(cat mcp-servers.json)" '.mcpServers = $$mcp' ~/.claude.json > ~/.claude.json.tmp \
		&& mv ~/.claude.json.tmp ~/.claude.json

LOCAL_JSONNET_FILES := settings.local.jsonnet mcp-servers.local.jsonnet

.PHONY: init-local
init-local:
	@for f in $(LOCAL_JSONNET_FILES); do \
		if [ -f "$$f" ]; then \
			echo "$$f already exists, skipping"; \
		else \
			echo '{}' > "$$f"; \
			echo "Created $$f"; \
		fi; \
	done

.PHONY: clean
clean:
	rm -f settings.json settings.json.tmp mcp-servers.json mcp-servers.json.tmp .settings.json.installed
