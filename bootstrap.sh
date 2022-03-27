#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || exit;

git pull --autostash --rebase;

function doIt() {
	stow --dotfiles -d "stow" "curl" -t "${HOME}";
	stow --dotfiles -d "stow" "git" -t "${HOME}";
	mkdir -p "${HOME}/.m2";
	stow --dotfiles -d "stow" "maven" -t "${HOME}";
	stow --dotfiles -d "stow" "misc" -t "${HOME}";
	mkdir -p "${HOME}/.config";
	stow --dotfiles -d "stow" "shell" -t "${HOME}";
	mkdir -p "${HOME}/.ssh/.config.d";
	stow --dotfiles -d "stow" "ssh" -t "${HOME}";
	stow --dotfiles -d "stow" "vim" -t "${HOME}";
	# load new config
	# shellcheck disable=SC1090
	source ~/.bash_profile;
}

function setGitUser() {
	local username, email, signingKey, signWithSSH;
	read -rp "Enter your Git Username: " username;
	read -rp "Enter your Git E-Mail address: " email;
	echo "
[user]

	name = ${username}
	email = ${email}
" > "${HOME}/.gituser"

	read -rp "Use GPG Commit Signing? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		signWithSSH="";
		read -rp "Sign with SSH: " -n 1;
		echo "";
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			signWithSSH="
[gpg]

	format = ssh";
		fi
		read -rp "Enter your GPG or SSH Signing Key ID: " signingKey;
		echo "
	signingkey = ${signingKey}

[commit]
	gpgsign = true

${signWithSSH}
" >> "${HOME}/.gituser"
	fi;
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
	doIt;
else
	read -rp "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;

if [ ! -f "${HOME}/.gituser" ]; then
	setGitUser;
fi
unset setGitUser;
