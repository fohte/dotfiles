.PHONY: all
all: clean romaji.rule

# pipefail: without it, a jsonnet/jq failure produces an empty romaji.rule that CI auto-format commits.
# Inlined on the recipe because macOS Make 3.81 ignores .SHELLFLAGS and Ubuntu /bin/sh is dash.
romaji.rule: romaji.jsonnet
	bash -o pipefail -c 'mise x -- jsonnet romaji.jsonnet | mise x -- jq -r "to_entries[] | \"\(.key),\(.value[0]),\(.value[1]),\(.value[1])\"" | iconv -f UTF-8 -t EUC-JP > $@'

clean:
	rm -f romaji.rule
