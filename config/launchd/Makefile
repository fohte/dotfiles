.PHONY: all clean

PLISTS := com.fohte.headroom-proxy.plist com.fohte.skk-watcher.plist

all: $(PLISTS)

# launchd plist XML doesn't expand $HOME or $PATH; substitute at build time.
%.plist: %.plist.in
	@mise=$$(command -v mise) && test -n "$$mise" || { echo "mise not found in PATH" >&2; exit 1; }; \
	skk_repo=$$(ghq list -p fohte/skk-dictionary | head -n1); \
	test -n "$$skk_repo" || { echo "skk-dictionary not cloned; run 'ghq get fohte/skk-dictionary'" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' \
	    -e "s|__MISE__|$$mise|g" \
	    -e "s|__SKK_DICT_REPO__|$$skk_repo|g" \
	    $< > $@.tmp && mv $@.tmp $@

clean:
	rm -f $(PLISTS)
