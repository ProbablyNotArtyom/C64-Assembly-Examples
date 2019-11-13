#!/bin/sh

if [ -z "$1" ]; then
	echo "Needs an argument."
	exit -1
else
	rm -f $1
	make $1
	x64sc $1
fi
