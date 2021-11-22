~/.config/git/ignore: ~/.config/git
	ln -sf $(CURDIR)/roles/git/files/.gitignore_global $@

symlink: ~/.config/git/ignore
