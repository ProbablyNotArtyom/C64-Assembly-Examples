#!/bin/sh

if [ -z "$1" ]; then
	echo "Needs an argument."
	exit -1
else
	make $1
	x64 $1
fi
