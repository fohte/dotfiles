.PHONY: all clean

PLISTS := com.fohte.headroom-proxy.plist

all: $(PLISTS)

# launchd plist XML doesn't expand $HOME or $PATH; substitute at build time.
%.plist: %.plist.in
	@mise=$$(command -v mise) && test -n "$$mise" || { echo "mise not found in PATH" >&2; exit 1; }; \
	sed -e 's|__HOME__|$(HOME)|g' -e "s|__MISE__|$$mise|g" $< > $@.tmp && mv $@.tmp $@

clean:
	rm -f $(PLISTS)
