#!/usr/bin/env bash

# Install Rosetta 2 on ARM Macs
if ! sysctl -n machdep.cpu.brand_string | grep -q 'Intel' ; then
	sudo softwareupdate --install-rosetta --agree-to-license
fi

# Check for Homebrew installation and install it if not present
if ! which brew >/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Upgrade any already-installed formulae.
brew upgrade

# Install everything inside Brewfile
brew bundle install --file "${script_dir}/Brewfile"

echo ""

cat <<EOF
If you do not want to run 'bootstrap.sh' please ensure the following paths are put as _PREFIXES_ to your \$PATH:
$(brew --prefix coreutils)/libexec/gnubin
$(brew --prefix curl)/bin
$(brew --prefix findutils)/libexec/gnubin
$(brew --prefix gnu-sed)/libexec/gnubin
$(brew --prefix grep)/libexec/gnubin

Additionally, you may want to add the following path _PREFIXES_ to your \$MANPATH:
$(brew --prefix coreutils)/libexec/gnuman
$(brew --prefix curl)/share/man
$(brew --prefix findutils)/libexec/gnuman
$(brew --prefix gnu-sed)/libexec/gnuman
$(brew --prefix grep)/libexec/gnuman

If you would like to map 'vi' so it opens the brew-installed vim run: ln -s $(brew --prefix vim) $(which vi)
EOF

# Switch to using brew-installed bash as default shell
if ! grep --fixed-strings --quiet "${BREW_PREFIX}/bin/bash" /etc/shells; then
	echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
	chsh -s "${BREW_PREFIX}/bin/bash"
fi
