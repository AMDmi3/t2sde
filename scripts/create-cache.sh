#!/bin/bash
#
# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/scripts/create-cache.sh
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. A copy of the GNU General Public
# License can be found at Documentation/COPYING.
# 
# Many people helped and are helping developing ROCK Linux. Please
# have a look at http://www.rocklinux.org/ and the Documentation/TEAM
# file for details.
# 
# --- ROCK-COPYRIGHT-NOTE-END ---

if [ "$#" != 5 ] ; then
	echo "Usage: $0 <rockver> <buildtime> <stage> <pkg> <var-adm-dir>" >&2
	exit 1
fi

rockver=$1
buildtime=$2
stagelevel=$3
pkg=$4
varadm=$5

LC_ALL=C date '+%n[TIMESTAMP] %s %c'
echo -e "[ROCKVER] $rockver\n"

echo "[LOGS]" $( cd ${varadm}/logs ; ls ?-$pkg.* )
echo

if [ -f "${varadm}/logs/$stagelevel-$pkg.log" ]
then
	echo "[BUILDTIME] $buildtime ($stagelevel)"
	echo "[SIZE] `grep "^Package Size: " \
		${varadm}/packages/$pkg | cut -f3- -d' '`"
	echo

	cut -f2- -d' ' "${varadm}/dependencies/$pkg" |
	fmt -70 | sed 's,^,[DEP] ,'
	echo
fi

for stagelevel in 0 1 2 3 4 5 6 7 8 9 ; do
	if [ -f "${varadm}/logs/$stagelevel-$pkg.err" ] ; then
		tail -n 50 "${varadm}/logs/$stagelevel-$pkg.err" | \
			sed "s,^,[$stagelevel-ERROR] ,"
		echo
	fi
done
