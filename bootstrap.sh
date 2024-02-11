#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || exit

git pull --autostash --rebase

function doIt() {
	echo "Creating expected XDG target directories"
	mkdir -v -p "${HOME}/.cache/bash"
	mkdir -v -p "${HOME}/.cache/ruby/gem"
	mkdir -v -p "${HOME}/.cache/vim/swap"
	mkdir -v -p "${HOME}/.config/"{bash,git}
	mkdir -v -p "${HOME}/.local/"{share,state}
	mkdir -v -p "${HOME}/.local/share/node"
	mkdir -v -p "${HOME}/.local/share/vim/bundle"
	mkdir -v -p "${HOME}/.local/state/vim/"{backup,undo}

	echo "Creating non-XDG target directories"
	mkdir -v -p "${HOME}/."{gradle,m2}
	mkdir -v -p "${HOME}/.ssh/config.d"
	mkdir -v -p "${HOME}/Library/Application Support/Code/User"

	echo "Linking files"
	for tmp in "stow"/*; do
		toolname=$(basename "${tmp}")
		[[ "${toolname}" != "vscode" ]] && stow --dotfiles --dir "stow" "${toolname}" --target "${HOME}"
	done
	stow --dotfiles --dir "stow" "vscode" --target "${HOME}/Library/Application Support/Code/User"

	# load new config
	echo "Loading profile"
	source "${HOME}/.bash_profile"
}

function initApps() {
	echo "Rebuild bat cache for custom theme support"
	bat cache --build
}

function setGitUser() {
	echo "Creating Git user config"

	local username email signingKey signWithSSH
	read -rp "Enter your Git Username: " username
	read -rp "Enter your Git E-Mail address: " email
	echo "
[user]

	name = ${username}
	email = ${email}
" >"${HOME}/.config/git/user"

	read -rp "Use GPG Commit Signing? (y/n) " -n 1
	echo ""
	if [[ ${REPLY} =~ ^[Yy]$ ]]; then
		signWithSSH=""
		read -rp "Sign with SSH? (y/n) " -n 1
		echo ""
		if [[ ${REPLY} =~ ^[Yy]$ ]]; then
			touch "${HOME}/.ssh/allowed_signers"
			signWithSSH="
[gpg]

	format = ssh

[gpg \"ssh\"]
	allowedSignersFile = ~/.ssh/allowed_signers"
		fi
		read -rp "Enter your GPG or SSH Signing Key ID: " signingKey
		echo "
	signingkey = ${signingKey}

[commit]
	gpgsign = true

${signWithSSH}
" >>"${HOME}/.config/git/user"
	fi
}

if [[ "${1}" == "--force" ]] || [[ "${1}" == "-f" ]]; then
	doIt
	initApps
else
	read -rp "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo ""
	if [[ ${REPLY} =~ ^[Yy]$ ]]; then
		doIt
		initApps
	fi
fi
unset doIt

if [[ ! -f "${HOME}/.config/git/user" ]]; then
	setGitUser
fi
unset setGitUser

echo "Done"
