#!/usr/bin/env bats

function setup() {
	load node_modules/bats-support/load.bash
	load node_modules/bats-assert/load.bash
	load node_modules/bats-file/load.bash

	DOTFILES_BREW_BUNDLE_LOCATION="${BATS_TEST_DIRNAME}/../Brewfile}"
	BREW_BUNDLE_LOCATION="${HOMEBREW_BUNDLE_FILE}"
	if [[ -z "${HOMEBREW_BUNDLE_FILE}" ]]; then
		BREW_BUNDLE_LOCATION="${DOTFILES_BREW_BUNDLE_LOCATION}"
	fi
}

@test "brew has been installed" {
	command -v brew
}

@test "brew bundle has been installed" {
	run brew bundle check --file="${BREW_BUNDLE_LOCATION}"
	assert_line "The Brewfile's dependencies are satisfied."
}

@test "vscode extensions have been been installed" {
	run brew bundle list --file="${BREW_BUNDLE_LOCATION}" --vscode
	assert_output
	extensions=$output

	run code --list-extensions
	assert_output
	for vscode_extension in ${extensions[@]}; do
		assert_line "${vscode_extension}"
	done
}
