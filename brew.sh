#!/usr/bin/env bash

# Install all homebrew packages inside Brewfile

# Check for Homebrew Installation
if ! which brew > /dev/null; then
		# Install Homebrew
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi;

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Upgrade any already-installed formulae.
brew upgrade

# Install everything inside Brewfile
brew bundle install
echo 'Be sure to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.'
echo 'Add `$(brew --prefix findutils)/libexec/gnubin` to `$PATH` if you would prefer these be the defaults.'
echo 'Be sure to add `$(brew --prefix gnu-sed)/libexec/gnubin` to `$PATH`.'
echo 'If you would like to map vi so it opens the brew-installed vim: ln -s /usr/local/bin/vim /usr/local/bin/vi'

ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;
