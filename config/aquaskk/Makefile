.PHONY: all
all: clean dvorakjp.rule

dvorakjp.rule: dvorakjp.utf8.rule
	nkf --utf8-input --euc $< > $@

clean:
	rm -f dvorakjp.rule
