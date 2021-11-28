#!/usr/bin/env bash

# Install all homebrew packages inside Brewfile

# Check for Homebrew Installation
if ! which brew > /dev/null; then
		# Install Homebrew
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi;

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Upgrade any already-installed formulae.
brew upgrade

# Install everything inside Brewfile
brew bundle install
# shellcheck disable=SC2034
echo '
Be sure to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
Add `$(brew --prefix findutils)/libexec/gnubin` to `$PATH` if you would prefer these be the defaults.
Be sure to add `$(brew --prefix gnu-sed)/libexec/gnubin` to `$PATH`.
If you would like to map vi so it opens the brew-installed vim: ln -s /usr/local/bin/vim /usr/local/bin/vi'

# Switch to using brew-installed bash as default shell
if ! grep -Fq "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;
