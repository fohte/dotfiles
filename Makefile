DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
DEPLOYFILES := $(wildcard .??*) bin
IGNOREFILES := .DS_Store .git .gitignore
DOTFILES := $(filter-out $(IGNOREFILES), $(DEPLOYFILES))

list:
	@$(foreach file, $(DOTFILES), /bin/ls -dF $(file);)

deploy:
	@$(foreach file, $(DOTFILES), ln -sfnv $(abspath $(file)) $(HOME)/$(file);)

update:
	@git pull origin master

install: update deploy

clean:
	@-$(foreach file, $(DOTFILES), rm -rfv $(HOME)/$(file);)
