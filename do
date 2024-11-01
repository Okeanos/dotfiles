#!/usr/bin/env bash

# script-template.sh https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038 by Maciej Radzikowski
# MIT License https://gist.github.com/m-radzikowski/d925ac457478db14c2146deadd0020cd
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-d list,of,dotfiles] -t local_repository_location [-r install_rosetta] show|link|unlink
Install or uninstall the dotfiles
Available options:
-h, --help         Print this help and exit
-v, --verbose      Print script debug info

-a, --dark-theme   Use Selenized Dark instead of Selenized Light as a theme
-d, --dotfiles     Comma separated list of dotfiles to link/install, defaults to everything
-n, --no-rosetta   Skip installing Rosetta on Apple Silicon (ARM)
-t, --target       The location where to put the Dotfiles repository, defaults to ~/Developer

show               Show which dotfiles exist
link               Install the (optionally) listed dotfiles and everything required for them
unlink             Uninstall the (optionally) listed dotfiles
EOF
}

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
	# script cleanup here
}

setup_colors() {
	if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
		# shellcheck disable=SC2034
		NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
	else
		# shellcheck disable=SC2034
		NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
	fi
}

msg() {
	echo >&2 -e "${1-}"
}

die() {
	local msg=$1
	local code=${2-1} # default exit status 1
	msg "$msg"
	msg ""
	usage
	exit "$code"
}

parse_params() {
	# default values of variables set from params
	rosetta="true"
	dotfiles="*"
	target="${HOME}/Developer"
	theme="light"

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		--no-color) NO_COLOR=1 ;;
		-a | --dark-theme) theme="dark" ;;
		-n | --no-rosetta) rosetta="false" ;;
		-d | --dotfiles)
			dotfiles="${2-}"
			shift
			;;
		-t | --target)
			target="${2-}"
			shift
			;;
		-?*) die "Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done

	args=("$@")

	# check required params and arguments
	[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"
	[[ "${args[0]}" != "show" ]] && [[ ${args[0]} != "link" ]] && [[ ${args[0]} != "unlink" ]] && die "Unknown script argument"

	return 0
}

parse_params "$@"
setup_colors

# script logic here
repository="${target}/dotfiles"

if [[ "${args[0]}" == "show" ]]; then
	msg "Available dotfiles:"

	if [[ ! -d "${repository}" ]]; then
		die "The location '${repository}' doesn't exist. Cannot list available dotfiles. Please checkout the repository first."
	fi

	find "${repository}/stow" -type d -printf '%P\n'

	msg ""
	msg "Use the leading directory name as input for the -d (--dotfiles) parameter."
elif [[ "${args[0]}" == "link" ]]; then
	msg "Installing prerequisites & setting up dotfiles"
	msg "Will use the following inputs:"
	msg "- Target location: '${target}'"
	msg "- Dotfiles repository location: '${repository}'"
	msg "- Dotfiles to install: '${dotfiles}'"
	msg "- Installing Rosetta: '${rosetta}'"
	msg "- Theme is Selenized (https://github.com/jan-warchol/selenized) in: '${theme}'"
	msg ""

	read -rp "Do you want to continue (y/n)? " -n 1
	msg ""
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		die "Installation canceled"
	fi

	msg ""

	msg "Installing prerequisites"

	if [[ "${rosetta}" == "true" ]] && ! sysctl -n machdep.cpu.brand_string | grep -q 'Intel'; then
		msg "Installing Rosetta"
		sudo softwareupdate --install-rosetta --agree-to-license
	else
		msg "${YELLOW}Skip installing Rosetta on Intel machines${NOFORMAT}"
	fi

	if ! which brew >/dev/null; then
		msg "Installing Homebrew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	# Save Homebrew’s installed location.
	BREW_PREFIX=$(brew --prefix)

	if [[ ! -d "${target}" ]]; then
		msg "Creating target location '${target}' for dotfiles"
		mkdir -p "${target}"
	fi

	if [[ -d "${repository}" ]]; then
		if git -C "${repository}" rev-parse; then
			msg "${YELLOW}Assuming the Git repository '${repository}' belongs to this script and will use it as a 'dotfiles' source.${NOFORMAT}"
		else
			die "${RED}The target location '${repository}' already exists but is ${NOFORMAT}not${RED} a Git repository. Please remove it and try again.${NOFORMAT}"
		fi
	else
		msg "Cloning dotfiles to: ${repository}"
		git clone --quiet https://github.com/Okeanos/dotfiles.git "${repository}"
	fi

	msg "Installing Brewfile contents"
	read -rp "Do you want to review the Brewfile now (y/n)? " -n 1
	msg ""
	if [[ ${REPLY} =~ ^[Yy]$ ]]; then
		msg "Brewfile contents:"
		msg "---"
		echo "$(<"${repository}/Brewfile")"
		msg "---"
	fi

	read -rp "Do you want to install the Brewfile contents (y/n)? " -n 1
	msg ""
	if [[ ${REPLY} =~ ^[Yy]$ ]]; then
		# Upgrade any already-installed formulae.
		brew upgrade
		# Install everything inside Brewfile
		brew bundle install --file "${repository}/Brewfile"
	else
		die "${RED}Aborting. The dotfiles require a number of tools from the Brewfile to work. Please update the Brewfile to your liking and run the installer again.${NOFORMAT}"
	fi

	if [[ -f "${BREW_PREFIX}/bin/bash" ]]; then
		if ! grep --fixed-strings --quiet "${BREW_PREFIX}/bin/bash" /etc/shells; then
			read -rp "Do you want to make the modern Bash ('${BREW_PREFIX}/bin/bash') known to the system (y/n)? " -n 1
			msg ""
			if [[ ${REPLY} =~ ^[Yy]$ ]]; then
				echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
			fi
		fi
		read -rp "Do you want to make the modern Bash ('${BREW_PREFIX}/bin/bash') your user shell (y/n)? " -n 1
		msg ""
		if [[ ${REPLY} =~ ^[Yy]$ ]]; then
			chsh -s "${BREW_PREFIX}/bin/bash"
		fi
	fi

	msg "Creating static locations to which to link the dotfiles. This prevents accidentally syncing sensitives files later on with the repository."
	msg "Creating XDG (https://specifications.freedesktop.org/basedir-spec/latest/) locations:"
	mkdir -v -p "${HOME}/.cache/bash"
	mkdir -v -p "${HOME}/.cache/ruby/gem"
	mkdir -v -p "${HOME}/.cache/vim/swap"
	mkdir -v -p "${HOME}/.config/"{bash,git}
	mkdir -v -p "${HOME}/.local/"{share,state}
	mkdir -v -p "${HOME}/.local/share/node"
	mkdir -v -p "${HOME}/.local/share/vim/bundle"
	mkdir -v -p "${HOME}/.local/state/vim/"{backup,undo}

	msg "Creating other locations"
	mkdir -v -p "${HOME}/."{gradle,m2}
	mkdir -v -p "${HOME}/.ssh/config.d"
	mkdir -v -p "${HOME}/Library/Application Support/Code/User"

	if [[ "${theme}" == "dark" ]]; then
		msg "${YELLOW}Converting dotfiles to Selenized Dark${NOFORMAT}"
		if command -v gsed >/dev/null; then
			gsed -i "s/background=light/background=dark/g" "${repository}/stow/shell/dot-config/vim/vimrc"
			gsed -i "s/Selenized-Light/Selenized-Dark/g" "${repository}/stow/shell/dot-config/bat/config"
		else
			sed -i '' "s/background=light/background=dark/g" "${repository}/stow/shell/dot-config/vim/vimrc"
			sed -i '' "s/Selenized-Light/Selenized-Dark/g" "${repository}/stow/shell/dot-config/bat/config"
		fi
	fi

	msg "Linking dotfiles: ${dotfiles}"
	msg "This may overwrite existing files in your home directory. Only continue if you are sure you want this to happen."
	read -rp "Do you want to link the named dotfiles (y/n)? " -n 1
	msg ""
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		die "${RED}Aborting. Please specify a subset of dotfiles if you do not want everything. The 'shell' parts are effectively required for the dotfiles to work/make sense.${NOFORMAT}"
	fi

	skip_tools=("vscode")
	for tmp in "${repository}/stow"/*; do
		toolname=$(basename "${tmp}")
		if [[ "${dotfiles}" != "*" ]] && [[ "${dotfiles}" != *"${toolname}"* ]]; then
			continue
		fi
		[[ ! "${skip_tools[*]}" == *"${toolname}"* ]] && stow --dotfiles --dir "stow" "${toolname}" --target "${HOME}"
	done
	if [[ "${dotfiles}" == "*" ]] || [[ "${dotfiles}" == *"vscode"* ]]; then
		stow --dotfiles --dir "${repository}/stow" "vscode" --target "${HOME}/Library/Application Support/Code/User"
	fi

	msg "Loading new bash profile with updated \$PATH etc."
	source "${HOME}/.bash_profile"

	if command -v bat >/dev/null; then
		msg "Rebuild bat cache so the theme works as expected"
		bat cache --build
	fi

	if [[ -f "${HOME}/.config/git/user" ]]; then
		msg "The Git user config '${HOME}/.config/git/user' already exists. Skipping setup."
	else
		msg "Creating Git user config"
		username=""
		email=""
		signing_enabled="false"
		signing_format="opengpg"
		sign_selection=""
		signing_key=""
		while [[ -z "${username}" ]]; do
			read -rp "Enter your Git Username: " username
			msg ""
		done
		while [[ -z "${email}" ]] && [[ "${email}" != *"@"* ]]; do
			read -rp "Enter your Git E-Mail address: " email
			msg ""
		done

		msg "Will set up Git commit signing, check the following links for more information:"
		msg "- Git User Signing Key documentation: https://git-scm.com/docs/git-config#Documentation/git-config.txt-usersigningKey"
		msg "- Git Signing Formats: https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat"
		msg ""
		msg "The Git user config '${HOME}/.config/git/user' can be updated later on if you want to set up commit signing later on."
		msg ""
		select signing_type in "GPG (OpenPGP)" "SSH" "Set up later"; do
			[[ -n "${signing_type}" ]] || {
				echo "Please select how you want to sign your Git commits." >&2
				continue
			}
			sign_selection="${signing_type}"
			break
		done
		if [[ "${sign_selection}" != "Set up later" ]]; then
			while [[ -z "${signing_key}" ]]; do
				read -rp "Enter your GPG or SSH Signing Key ID: " signing_key
				msg ""
			done

			if [[ "${sign_selection}" == "SSH" ]]; then
				touch "${HOME}/.ssh/allowed_signers"
				signing_format="ssh"
			fi
		fi

		printf '[%s]\n' \
				"[user]" \
				"" \
				"	name = ${username}" \
				"	email = ${email}" \
				"	signingKey = ${signing_key}" \
				"" \
				"[gpg]" \
				"" \
				"	format = ${signing_format}" \
				"" \
				"[gpg \"ssh\"]" \
				"" \
				"	allowedSignersFile = ~/.ssh/allowed_signers" \
				"" \
				"[commit]" \
				"" \
				"	gpgsign = ${signing_enabled}" \
		>"${HOME}/.config/git/user"
	fi

	msg ""
	msg "${GREEN}Done setting things up. You probably want to restart your shell now (type 'exit' or Ctrl+D).${NOFORMAT}"
elif [[ "${args[0]}" == "unlink" ]]; then
	msg "Unlinking dotfiles: ${dotfiles}"

	if [[ ! -d "${repository}" ]]; then
		die "The location '${repository}' doesn't exist. Cannot unlink dotfiles."
	fi

	read -rp "This will unlink the dotfiles from your home directory. No files will actually be deleted. Are you sure? (y/n) " -n 1
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		die "${RED}Aborting. Please specify a subset of dotfiles if you do not want to unlink everything.${NOFORMAT}"
	fi

	for tmp in "stow"/*; do
		toolname=$(basename "${tmp}")
		if [[ "${dotfiles}" != "*" ]] && [[ "${dotfiles}" != *"${toolname}"* ]]; then
			continue
		fi
		if [[ "${toolname}" != "vscode" ]]; then
			msg "Unlinking '${toolname}' from '${HOME}'"
			stow --dotfiles --delete --dir "stow" "${toolname}" --target "${HOME}"
		fi
	done
	if [[ "${dotfiles}" == "*" ]] || [[ "${dotfiles}" == *"vscode"* ]]; then
		msg "Unlinking 'vscode' from '${HOME}/Library/Application Support/Code/User'"
		stow --dotfiles --dir "stow" "vscode" --target "${HOME}/Library/Application Support/Code/User"
	fi


	msg ""
	msg "${GREEN}Done unlinking the dotfiles. You probably want to restart your shell now (type 'exit' or Ctrl+D).${NOFORMAT}"
fi
