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

@test "expected commands exist on \$PATH" {
	# TODO dynamically source this list from brew, e.g. via a combination of:
	# tools=$(brew bundle list --file="${BREW_BUNDLE_LOCATION}" --brews)
	# brew info ${tool} --formulae --json=v2 | jq --raw-output '.formulae'
	tools=(
		"bats"
		"curl"
		"dive"
		"gh"
		"git"
		"go"
		"grep"
		"htop"
		"jq"
		"mvn"
		"netcat"
		"node"
		"pigz"
		"starship"
		"stow"
		"tree"
		"vim"
		"wget"
		"yarn"
		"yq"
	)

	for tool in "${tools[@]}"; do
		command -v "${tool}"
	done
}

@test "GNU grep is used by default" {
	run grep --version
	assert_output --partial "GNU grep"
}

@test "GNU sed is used by default" {
	run sed --version
	assert_output --partial "GNU sed"
}

@test "curl has expected version" {
	expected_version=$(brew info curl --formulae --json=v2 | jq --raw-output '.formulae[0].versions.stable')

	run curl --version
	assert_output --regexp "^curl ${expected_version}"
}
