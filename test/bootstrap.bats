#!/usr/bin/env bats

function setup() {
	load node_modules/bats-support/load.bash
	load node_modules/bats-assert/load.bash
	load node_modules/bats-file/load.bash

	STOW_FILES_LOCATION="${BATS_TEST_DIRNAME}/../stow"
	STOW_FILES_ABSOLUTE_LOCATION=$(realpath --canonicalize-existing ${STOW_FILES_LOCATION})
	DOTFILES_RELATIVE_LOCATION="$(realpath --canonicalize-existing --relative-base=../../.. ${STOW_FILES_LOCATION})"
}

@test "expected directories have been created" {
	paths=(
		"${HOME}/.cache"
		"${HOME}/.cache/bash"
		"${HOME}/.cache/ruby/gem"
		"${HOME}/.cache/vim/swap"
		"${HOME}/.config"
		"${HOME}/.local/share"
		"${HOME}/.local/share/node"
		"${HOME}/.local/share/vim"
		"${HOME}/.local/share/vim/bundle"
		"${HOME}/.local/state"
		"${HOME}/.local/state/vim"
		"${HOME}/.local/state/vim/backup"
		"${HOME}/.local/state/vim/undo"
		"${HOME}/.gradle"
		"${HOME}/.m2"
		"${HOME}/.ssh/config.d"
		"${HOME}/Library/Application Support/Code/User"
	)

	for path in "${paths[@]}"; do
		assert_dir_exists "${path}"
	done
}

@test "expected symlinks exist" {
	for tool_path in "${STOW_FILES_ABSOLUTE_LOCATION}"/*; do
		tool=$(basename ${tool_path})
		if [[ "${tool}" == "vscode" ]]; then
			assert_symlink_to "${tool_path}/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"
		else
			run stow --no --dotfiles --dir "${STOW_FILES_LOCATION}" "${tool}" --target "${HOME}" --verbose 2
			assert_output

			for file in "${tool_path}"/*; do
				if [[ -f "${file}" ]]; then
					file_path=$(realpath --canonicalize-existing ${file})
					file_name=$(basename ${file_path})
					assert_line "--- Skipping ${file_name/dot-/\.} as it already points to ${DOTFILES_RELATIVE_LOCATION}/${tool}/${file_name}"
				else
					# TODO handle nested directories with no top-level files
					# - maven/.m2/toolchains.xml
					# - ssh/.ssh/*
					echo "# Test for ${file} not implemented yet" >&3
				fi
			done
		fi
	done
}
