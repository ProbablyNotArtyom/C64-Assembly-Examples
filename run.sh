#!/bin/sh

if [ -z "$@" ]; then
	echo "Needs an argument."
	exit -1
else
	x64sc $@
fi
