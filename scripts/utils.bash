#!/usr/bin/env bash

pc_env=''

case "$OSTYPE" in
darwin*)
	pc_env='macos'
	;;
linux*)
	if grep -q microsoft /proc/version; then
		pc_env='wsl'
	else
		pc_env='linux'
	fi
	;;
*) pc_env='other' ;;
esac

is_wsl() {
	[[ $pc_env == wsl ]]
}

is_macos() {
	[[ $pc_env == macos ]]
}

is_linux() {
	[[ $pc_env == linux ]]
}
