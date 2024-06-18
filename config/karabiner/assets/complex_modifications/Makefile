ALL_JSONNETS := $(wildcard *.jsonnet)
ALL_JSONS := $(ALL_JSONNETS:.jsonnet=.json)

.PHONY: build
build: clean $(ALL_JSONS)

.PHONY: clean
clean:
	rm -f $(ALL_JSONS)

%.json: %.jsonnet
	jsonnet $< -o $@
	prettier -w --parser json $@
