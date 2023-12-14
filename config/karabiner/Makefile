SRC_DIR := assets/complex_modifications
JSON_FILES := $(patsubst %.jsonnet,%.json,$(wildcard $(SRC_DIR)/*.jsonnet))

.PHONY: all
all: clean $(JSON_FILES)

clean:
	rm -f $(JSON_FILES)

%.json: %.jsonnet
	jsonnet $< | prettier -w --parser json > $@
