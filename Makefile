DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml .claude-dotfiles
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

all: install

help:
	@echo "make list                  #=> Show dot files in this repo"
	@echo "make deploy                #=> Create symlink to home directory"
	@echo "make init                  #=> Setup environment settings"
	@echo "make test                  #=> Test dotfiles and init scripts"
	@echo "make update                #=> Fetch changes for this repo"
	@echo "make update-cage           #=> Update cage config from projects.yml"
	@echo "make install               #=> Run make update, deploy, init"
	@echo "make clean                 #=> Remove the dot files and this repo"

list:
	@$(foreach val, $(DOTFILES), ls -dF $(val);)

deploy:
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@$(MAKE) update-cage

init:
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/init/init.sh

update:
	git pull origin master

update-cage:
	@echo "Updating cage config from projects.yml..."
	@$(DOTPATH)/bin/update-cage-config

install: update deploy init
	@exec $$SHELL

clean:
	@echo 'Remove dot files in your home directory...'
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(val);)
	-rm -rf $(DOTPATH)
