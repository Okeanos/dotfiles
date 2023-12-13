#!/usr/bin/env bats

function setup() {
	load node_modules/bats-support/load.bash
	load node_modules/bats-assert/load.bash
	load node_modules/bats-file/load.bash
}

@test "git command exists" {
	command -v git
}

@test "git generic config is set up" {
	assert_file_exists "${XDG_CONFIG_HOME}/git/config"

	run git config --get core.autocrlf
	assert_output "input"

	run git config --get pull.rebase
	assert_output "true"

	run git config --get rebase.autostash
	assert_output "true"
}

@test "git generic ignore is set up" {
	assert_file_exists "${HOME}/.gitignore"

	assert_file_not_empty "${HOME}/.gitignore"
}

@test "git generic attributes is set up" {
	assert_file_exists "${HOME}/.gitattributes"
}

@test "git user is set up" {
	assert_file_exists "${XDG_CONFIG_HOME}/git/user"

	run git config --get user.name
	assert_output

	run git config --get user.email
	assert_output --partial "@"
}

@test "git commit signing is set up" {
	run git config --get user.signingKey
	assert_output

	run git config --get commit.gpgsign
	assert_output "true"
}
