#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || exit;

function doIt() {
	for tmp in "stow"/*; do
		stow --dotfiles -D -d "stow" "$(basenname "${tmp}")" -t "${HOME}";
	done
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
	doIt;
else
	read -rp "This will unlink the dotfiles from your home directory. No files will actually be deleted. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
		echo "Please logout from your shell (CTRL+D) for the changes to be applied."
	fi;
fi;
unset doIt;