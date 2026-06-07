.PHONY: all clean

PLISTS := com.fohte.headroom-proxy.plist

all: $(PLISTS)

# Render plist from .in template. launchd plist XML doesn't expand $HOME,
# so substitute __HOME__ at build time.
%.plist: %.plist.in
	sed 's|__HOME__|$(HOME)|g' $< > $@.tmp && mv $@.tmp $@

clean:
	rm -f $(PLISTS)
