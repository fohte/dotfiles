.PHONY: all clean romaji.rule
all: romaji.rule

# pipefail + write-then-rename: a jsonnet/jq failure must never leave an empty romaji.rule,
# which AquaSKK would load and CI auto-format would commit.
# Inlined on the recipe because macOS Make 3.81 ignores .SHELLFLAGS and Ubuntu /bin/sh is dash.
romaji.rule: romaji.jsonnet
	bash -o pipefail -c 'mise x -- jsonnet romaji.jsonnet | mise x -- jq -r "to_entries[] | \"\(.key),\(.value[0]),\(.value[1]),\(.value[1])\"" | iconv -f UTF-8 -t EUC-JP > $@.tmp && mv $@.tmp $@ || { rm -f $@.tmp; exit 1; }'

clean:
	rm -f romaji.rule
