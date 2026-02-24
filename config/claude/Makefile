.PHONY: all
all:
	mise x -- jsonnet \
		--ext-str CONTEXT7_API_KEY="$${CONTEXT7_API_KEY}" \
		mcp-servers.jsonnet \
	| jq -s '.[0] as $$mcp | .[1] | .mcpServers = $$mcp' - ~/.claude.json \
	> ~/.claude.json.tmp \
	&& mv ~/.claude.json.tmp ~/.claude.json
