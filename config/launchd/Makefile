.PHONY: all clean

BASE_PLISTS := com.fohte.codex-app-server.plist com.fohte.codex-app-server-reloader.plist com.fohte.skk-watcher.plist
PRIVATE_PLIST := com.fohte.claude-rate-limits.plist
MACHINE_ROLE := $(shell ../bin/dot-role get name)

PLISTS := $(BASE_PLISTS)
ifeq ($(MACHINE_ROLE),private)
PLISTS += $(PRIVATE_PLIST)
endif

all: $(PLISTS)

# launchd plist XML doesn't expand $HOME or resolve commands through a login shell.
com.fohte.codex-app-server.plist: com.fohte.codex-app-server.plist.in
	@codex=$$(command -v codex) && test -n "$$codex" || { echo "codex not found in PATH" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__CODEX__|$$codex|g" \
	    $< > $@.tmp && mv $@.tmp $@

com.fohte.codex-app-server-reloader.plist: com.fohte.codex-app-server-reloader.plist.in
	@codex=$$(command -v codex) && test -n "$$codex" || { echo "codex not found in PATH" >&2; exit 1; }; \
	caskroom=$$(brew --caskroom) || exit 1; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__CODEX__|$$codex|g" \
	    -e "s|__CODEX_CASKROOM__|$$caskroom/codex|g" \
	    $< > $@.tmp && mv $@.tmp $@

com.fohte.skk-watcher.plist: com.fohte.skk-watcher.plist.in
	@mise=$$(command -v mise) && test -n "$$mise" || { echo "mise not found in PATH" >&2; exit 1; }; \
	skk_repo=$$(ghq list -p fohte/skk-dictionary | head -n1); \
	test -n "$$skk_repo" || { echo "skk-dictionary not cloned; run 'ghq get fohte/skk-dictionary'" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__MISE__|$$mise|g" \
	    -e "s|__SKK_DICT_REPO__|$$skk_repo|g" \
	    $< > $@.tmp && mv $@.tmp $@

ifeq ($(MACHINE_ROLE),private)
$(PRIVATE_PLIST): $(PRIVATE_PLIST).in
	@bun=$$(command -v bun) && test -n "$$bun" || { echo "bun not found in PATH" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__BUN__|$$bun|g" \
	    $< > $@.tmp && mv $@.tmp $@
endif

clean:
	rm -f $(BASE_PLISTS) $(PRIVATE_PLIST)
