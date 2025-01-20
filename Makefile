.PHONY: all
all:
	@find . -type f -name Makefile -not -path './Makefile' | while read makefile; do \
		dir=$$(dirname $$makefile); \
		echo "> Running make in $$dir"; \
		$(MAKE) -C $$dir; \
	done
