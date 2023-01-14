#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || exit;

function doIt() {
	for tmp in "stow"/*; do
		stow --dotfiles --delete --dir "stow" "$(basenname "${tmp}")" --target "${HOME}";
	done
}

if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
	doIt;
	echo "Please logout from your shell (CTRL+D or type 'exit') for the changes to be applied."
else
	read -rp "This will unlink the dotfiles from your home directory. No files will actually be deleted. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
		echo "Please logout from your shell (CTRL+D or type 'exit') for the changes to be applied."
	fi;
fi;
unset doIt;
