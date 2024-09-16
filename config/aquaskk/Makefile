.PHONY: all
all: clean romaji.rule

romaji.rule: romaji.jsonnet
	jsonnet romaji.jsonnet | jq -r 'to_entries[] | "\(.key),\(.value[0]),\(.value[1]),\(.value[1])"' | nkf --utf8-input --euc > $@

clean:
	rm -f romaji.rule
