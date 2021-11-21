~/.git/config/ignore:
	ln -sf $(CURDIR)/roles/git/files/.gitignore_global $@

symlink: ~/.git/config/ignore
