# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
#
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
#
# ROCK Linux: rock-src/package/*/bashcompletion/profile_d_bashcomp.sh
# Copyright (C) 1998 - 2004 ROCK Linux Project
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

# off ..... just default tab completion
# intern .. smart tab completion with shell function (fast)
# extern .. smart tab completion with ext. progs (slow but cleaner)
#
completion_mode=off

if [ -n "$PS1" ]
then
	case "$completion_mode" in
	  intern)
		source /etc/bash_completion
		;;
	  extern)
		shopt -s extglob progcomp
		eval "$( bashcomp )"
		;;
	esac
fi

unset completion_mode

