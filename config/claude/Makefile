SHELL := bash

# Build a jsonnet file, merging with a .local.jsonnet overlay if it exists.
# The local overlay can use +: syntax for deep merging (e.g. permissions+: { allow+: [...] }).
# External variables referenced via env('VAR_NAME') are auto-detected from source files
# and passed as --ext-str flags (jsonnet reads them from environment variables).
# usage: $(call jsonnet,<base.jsonnet>)
define jsonnet
$(strip \
	mise x -- jsonnet \
		$$(grep -oh "env('[^']*')" $(1) $(wildcard $(basename $(1)).local.jsonnet) \
			| sort -u | sed "s/env('\\(.*\\)')/--ext-str \\1/") \
		$(if $(wildcard $(basename $(1)).local.jsonnet), \
			-e '(import "$(1)") + (import "$(basename $(1)).local.jsonnet")', \
			$(1) \
		) \
)
endef

BUILD_TARGETS := settings.json mcp-servers.json

.PHONY: all
all: $(BUILD_TARGETS) install

settings.json: settings.jsonnet $(wildcard settings.local.jsonnet)
	$(call jsonnet,settings.jsonnet) > $@.tmp && mv $@.tmp $@

mcp-servers.json: mcp-servers.jsonnet $(wildcard mcp-servers.local.jsonnet)
	$(call jsonnet,mcp-servers.jsonnet) > $@.tmp && mv $@.tmp $@

# Detect if ~/.claude/settings.json was modified outside of jsonnet (e.g. by Claude Code).
# Compares the last installed output against the current file.
.PHONY: check-settings
check-settings: settings.json
	@if [ -f ~/.claude/settings.json ] && [ -f .settings.json.installed ]; then \
		expected=$$(jq -S . .settings.json.installed | shasum -a 256 | cut -d' ' -f1); \
		actual=$$(jq -S . ~/.claude/settings.json | shasum -a 256 | cut -d' ' -f1); \
		if [ "$$expected" != "$$actual" ]; then \
			echo "error: ~/.claude/settings.json has been modified outside of jsonnet." >&2; \
			echo "" >&2; \
			echo "--- .settings.json.installed (expected)" >&2; \
			echo "+++ ~/.claude/settings.json (actual)" >&2; \
			diff <(jq -S . .settings.json.installed) <(jq -S . ~/.claude/settings.json) >&2 || true; \
			echo "" >&2; \
			echo "To force overwrite, run: make -C config/claude clean install" >&2; \
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
