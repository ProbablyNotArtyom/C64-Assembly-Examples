#!/bin/sh

if [[ -z "$@" ]]; then
	echo "Needs an argument."
	exit -1
elif [[ "$1" == "--debug" ]]; then
	make $2
	c64debugger -unpause -reset -autojmp -symbols "$(dirname $2)/syms/$(basename -s .prg $2).sym" -prg "$2"
else
	make $1
	x64sc $1
fi
