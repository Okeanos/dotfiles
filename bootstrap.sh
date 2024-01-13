#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || exit

git pull --autostash --rebase

function doIt() {
	echo "Creating target directories"
	mkdir -v -p "${HOME}/.config"
	mkdir -v -p "${HOME}/.gem"
	mkdir -v -p "${HOME}/.m2"
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

function setGitUser() {
	echo "Creating Git user config"

	local username email signingKey signWithSSH
	read -rp "Enter your Git Username: " username
	read -rp "Enter your Git E-Mail address: " email
	echo "
[user]

	name = ${username}
	email = ${email}
" >"${HOME}/.gituser"

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
" >>"${HOME}/.gituser"
	fi
}

if [[ "${1}" == "--force" ]] || [[ "${1}" == "-f" ]]; then
	echo "Linking dotfiles"
	doIt
else
	read -rp "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo ""
	if [[ ${REPLY} =~ ^[Yy]$ ]]; then
		echo "Linking dotfiles"
		doIt
	fi
fi
unset doIt

if [[ ! -f "${HOME}/.gituser" ]]; then
	setGitUser
fi
unset setGitUser

echo "Done"
