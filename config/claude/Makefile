# Build a jsonnet file, merging with a .local.jsonnet overlay if it exists.
# The local overlay can use +: syntax for deep merging (e.g. permissions+: { allow+: [...] }).
# usage: $(call jsonnet,<base.jsonnet>[,--ext-str KEY=val ...])
define jsonnet
$(strip \
	mise x -- jsonnet $(2) $(if $(wildcard $(basename $(1)).local.jsonnet), \
		-e '(import "$(1)") + (import "$(basename $(1)).local.jsonnet")', \
		$(1) \
	) \
)
endef

.PHONY: all
all: settings.json mcp-servers.json

settings.json: settings.jsonnet $(wildcard settings.local.jsonnet)
	@if [ -f ~/.claude/settings.json ]; then \
		expected=$$($(call jsonnet,settings.jsonnet) | jq -S .); \
		actual=$$(jq -S . ~/.claude/settings.json); \
		if [ "$$expected" != "$$actual" ]; then \
			echo "error: ~/.claude/settings.json has been modified outside of jsonnet." >&2; \
			echo "Run 'diff <(jq -S . ~/.claude/settings.json) <(make -C config/claude print-settings | jq -S .)' to inspect." >&2; \
			exit 1; \
		fi; \
	fi
	$(call jsonnet,settings.jsonnet) > ~/.claude/settings.json

.PHONY: print-settings
print-settings:
	@$(call jsonnet,settings.jsonnet)

mcp-servers.json: mcp-servers.jsonnet $(wildcard mcp-servers.local.jsonnet)
	$(call jsonnet,mcp-servers.jsonnet,--ext-str CONTEXT7_API_KEY="$${CONTEXT7_API_KEY}") \
	| jq -s '.[0] as $$mcp | .[1] | .mcpServers = $$mcp' - ~/.claude.json \
	> ~/.claude.json.tmp \
	&& mv ~/.claude.json.tmp ~/.claude.json
