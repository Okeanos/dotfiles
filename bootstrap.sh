#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
	stow -d "stow" "curl" -t "${HOME}";
	stow -d "stow" "git" -t "${HOME}";
	mkdir -p "${HOME}/.m2";
	stow -d "stow" "maven" -t "${HOME}";
	stow -d "stow" "misc" -t "${HOME}";
	stow -d "stow" "shell" -t "${HOME}";
	mkdir -p "${HOME}/.ssh";
	stow -d "stow" "ssh" -t "${HOME}";
	stow -d "stow" "vim" -t "${HOME}";
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
