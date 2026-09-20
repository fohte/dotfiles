.PHONY: all clean

PLISTS := com.fohte.codex-app-server.plist com.fohte.skk-watcher.plist

all: $(PLISTS)

# launchd plist XML doesn't expand $HOME or resolve commands through a login shell.
com.fohte.codex-app-server.plist: com.fohte.codex-app-server.plist.in
	@codex=$$(command -v codex) && test -n "$$codex" || { echo "codex not found in PATH" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__CODEX__|$$codex|g" \
	    $< > $@.tmp && mv $@.tmp $@

com.fohte.skk-watcher.plist: com.fohte.skk-watcher.plist.in
	@mise=$$(command -v mise) && test -n "$$mise" || { echo "mise not found in PATH" >&2; exit 1; }; \
	skk_repo=$$(ghq list -p fohte/skk-dictionary | head -n1); \
	test -n "$$skk_repo" || { echo "skk-dictionary not cloned; run 'ghq get fohte/skk-dictionary'" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__MISE__|$$mise|g" \
	    -e "s|__SKK_DICT_REPO__|$$skk_repo|g" \
	    $< > $@.tmp && mv $@.tmp $@

clean:
	rm -f $(PLISTS)
