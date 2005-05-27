# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../webmin/stone_mod_webmin.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
# [MAIN] 80 webmin Webmin Configuration

WEBMINDIR=/opt/webmin
USERFILE=/etc/opt/webmin/miniserv.users
CONFFILE=/etc/opt/webmin/miniserv.conf
ACLFILE=/etc/opt/webmin/webmin.acl

set_pw() {
	LOGIN="$1"
	PASSWORD=1
	PASSWORD2=2
	while [ "$PASSWORD" != "$PASSWORD2" ] ; do
		gui_input "Enter $LOGIN password" "" PASSWORD ;
		gui_input "Re-Enter $LOGIN password" "" PASSWORD2 ;
		if [ "$PASSWORD" != "$PASSWORD2" ] ; then
			gui_message "Passwords are different: no change!"
		fi
	done
	if [ "$2" = 1 ] ; then
		gui_message "Changeing $LOGIN password."
		tmp="`mktemp`"
		sed "/^$LOGIN:.*/ s/^$LOGIN:[^:]*:/$LOGIN:`perl -e 'print crypt($ARGV[0], "XX");' "$PASSWORD"`:/ ;" < $USERFILE > $tmp
		cat $tmp > $USERFILE ; rm -f $tmp
	else
		gui_message "Setting $LOGIN password."
		perl -e 'print "$ARGV[0]:",crypt($ARGV[1], "XX"),":0::\n"' "$LOGIN" "$PASSWORD" >> $USERFILE
	fi

}

set_acl() {
	LOGIN="$1"
	ALLMODS=`echo $WEBMINDIR/*/module.info | sed -e "s,$WEBMINDIR/,,g ; s,/module.info,,g"`
	if [ "$2" = 1 ] ; then
		gui_message "Resetting $LOGIN acls to default."
		tmp="`mktemp`"
		sed "/^$LOGIN:.*/ s/:.*/: $ALLMODS/ ;" < $ACLFILE > $tmp
		cat $tmp > $ACLFILE ; rm -f $tmp
	else
		gui_message "Setting $LOGIN acls to default."
		echo "$LOGIN: $ALLMODS" >> $ACLFILE
	fi
}

set_user() {
	gui_input "Enter user login" "admin" LOGIN ;
	if [ "`grep \"^$LOGIN:\" $USERFILE`" = "" ] ; then
		gui_message "New user $LOGIN !"
		set_pw $LOGIN 0
		set_acl $LOGIN 0
	else
		gui_message "Existing user $LOGIN !"
		if gui_yesno "Change $LOGIN password?" ; then
			set_pw $LOGIN 1
		fi
		if gui_yesno "Reset $LOGIN acls?" ; then
			set_acl $LOGIN 1
		fi
	fi
}

edit() {
	gui_edit "Edit file $1" "$1"
	exec $STONE webmin
}

main() {
    while
	cmd="gui_menu webmin 'Webmin Configuration - Select an item to'"

	cmd="$cmd 'Add/(Re-)Set user password and acls' 'set_user'"

	cmd="$cmd '' '' 'Configure runlevels for webmin service'"
	cmd="$cmd '$STONE runlevel edit_srv webmin'"
	cmd="$cmd '(Re-)Start webmin init script'"
	cmd="$cmd '$STONE runlevel restart webmin'"
	cmd="$cmd '' ''"

	cmd="$cmd 'View/Edit $CONFFILE file'  'edit $CONFFILE'"

	eval "$cmd"
    do : ; done
}

