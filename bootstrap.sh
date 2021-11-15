#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
	stow --dotfiles -d "stow" "curl" -t "${HOME}";
	stow --dotfiles -d "stow" "git" -t "${HOME}";
	mkdir -p "${HOME}/.m2";
	stow --dotfiles -d "stow" "maven" -t "${HOME}";
	stow --dotfiles -d "stow" "misc" -t "${HOME}";
	stow --dotfiles -d "stow" "shell" -t "${HOME}";
	mkdir -p "${HOME}/.ssh";
	stow --dotfiles -d "stow" "ssh" -t "${HOME}";
	stow --dotfiles -d "stow" "vim" -t "${HOME}";
	# load new config
	source ~/.bash_profile;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
