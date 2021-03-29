#!/bin/bash
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by scripts/Create-CopyPatch.
# 
# T2 SDE: package/*/mkinitrd/mkinitrd.sh
# Copyright (C) 2005 - 2021 The T2 SDE Project
# Copyright (C) 2005 - 2019 René Rebe <rene@exactcode.de>
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

set -e

map=`mktemp`
firmware=
minimal=
network=1
archprefix=

declare -A vitalmods
vitalmods[qla1280.ko]=1 # Sgi Octane
vitalmods[qla2xxx.ko]=1 # Sun Blade
vitalmods[tg3.ko]=1 # Sun Fire
vitalmods[xhci-pci.ko]=1 # probably every modern machine

filter="-e isofs -e ext4 -e ata_piix -e pata_legacy -e pata_acpi -e floppy"

declare -A added

if [ $UID != 0 ]; then
	echo "Non root - exiting ..."
	exit 1
fi

while [ "$1" ]; do
  case $1 in
	[0-9]*) kernelver="$1" ;;
	-R) root="$2" ; shift ;;
	-a) archprefix="$2" ; shift ;;
	--firmware) firmware=1 ;;
	--minimal) minimal=1 ;;
	--network) network=0 ;;
	-e) filter="$filter $2" ; shift ;;
	*) echo "Usage: mkinitrd [ --firmware ] [ -R root ] [ kernelver ]"
	   exit 1 ;;
  esac
  shift
done

[ "$minimal" != 1 ] && filter="$filter -e reiserfs -e btrfs -e /jfs -e /xfs
-e /udf -e /unionfs -e ntfs -e /fat -e /hfs
-e /ata/ -e /scsi/ -e /fusion/ -e /sdhci/ -e nvme
-e dm-mod -e dm-raid -e md/raid -e dm/mirror -e dm/linear -e dm-crypt -e dm-cache
-e /aes -e /sha -e /blake -e /cbc
-e cciss -e ips -e virtio -e nls_cp437 -e nls_iso8859-1 -e nls_utf8
-e /.hci -e usb-common -e usb-storage -e sbp2 -e uas
-e usbhid -e i2c-hid -e hid-generic -e hid-multitouch -e hid-apple -e hid-microsoft"

[ "$network" = 1 ] && filter="$filter -e /ipv4/ -e '/ipv6\.' -e ethernet"


[ "$kernelver" ] || kernelver=`uname -r`
[ "$moddir" ] || moddir="$root/lib/modules/$kernelver"

modinfo="${archprefix}modinfo -b $moddir -k $kernelver"
depmod=${archprefix}depmod

echo "Kernel: $kernelver, module dir: $moddir"

if [ ! -d $moddir ]; then
	echo "Module dir $moddir does not exist!"
	exit 2
fi

sysmap=""
[ -f "$root/boot/System.map-$kernelver" ] && sysmap="$root/boot/System.map-$kernelver"

if [ -z "$sysmap" ]; then
	echo "System.map-$kernelver not found!"
	exit 2
fi

echo "System.map: $sysmap"

# check needed tools
for x in cpio gzip; do
	if ! type -p $x >/dev/null; then
		echo "$x not found!"
		exit 2
	fi
done

tmpdir="$map.d"

# create basic structure
#
rm -rf $tmpdir >/dev/null

echo "Create dirtree ..."

mkdir -p $tmpdir/{dev,bin,sbin,proc,sys,lib/modules,lib/udev,etc/hotplug.d/default}
mknod $tmpdir/dev/console c 5 1

# copy the basic / rootfs kernel modules
#
echo "Copying kernel modules ..."

(
  add_depend() {
     local skipped=
     local x="$1"

     # expand to full name if it was a depend
     [ $x = ${x##*/} ] && x=`sed -n "/\/$x\.ko.*/{p; q}" $map`

     if [ "${added["$x"]}" != 1 ]; then
	added["$x"]=1

	local module=${x##*/}
	echo -n "$module "

	# strip $root prefix
	xt=${x##$root}

	# does it need firmware?
	fw="`$modinfo -F firmware $x`"
	if [ "$fw" ]; then
	     echo -e -n "\nWarning: $module needs firmware"
	     if [ "$firmware" -o "${vitalmods[$module]}" ]; then
		for fn in $fw; do
		    local fn="/lib/firmware/$fn"
		    local dir="$tmpdir${fn%/*}"
		    if [ ! -e "$root$fn" ]; then
			if [ "${vitalmods[$module]}" ]; then
			    echo ", not found, vital, including anyway"
			else
			    echo ", not found, skipped"
			    skipped=1
			fi
		    else
			mkdir -p "$dir"
			echo -n ", $fn"
			cp -af "$root$fn" "$dir/"
			# TODO: copy source if symlink
			[ -f "$tmpdir$fn" ] && zstd -19 --rm -f --quiet "$tmpdir$fn"
		    fi
		done
		echo
	     else
		echo ", skipped"
		skipped=1
	     fi
	fi

	if [ -z "$skipped" ]; then
	    mkdir -p `dirname $tmpdir$xt`
	    cp -af $x $tmpdir$xt
	    zstd -19 --rm -f --quiet $tmpdir$xt

	    # add it's deps, too
	    for fn in `$modinfo -F depends $x | sed 's/,/ /g'`; do
		add_depend "$fn"
	    done
	fi
     else
        #echo "already there"
	:
     fi
  }

  find $moddir/kernel -type f > $map
  grep -v -e /wireless/ -e netfilter $map | grep $filter |
  while read fn; do
	add_depend "$fn"
  done
) | fold -s; echo

# generate map files
#
$depmod -ae -b $tmpdir -F $sysmap $kernelver
# only keep the .bin-ary files
rm $tmpdir/lib/modules/$kernelver/{modules.alias,modules.dep,modules.symbols}

echo "Injecting programs and configuration ..."

# copying config
#
cp -ar $root/etc/{group,udev} $tmpdir/etc/

[ -e $root/lib/udev/rules.d ] && cp -ar $root/lib/udev/rules.d $tmpdir/lib/udev/
[ -e $root/etc/mdadm.conf ] && cp -ar $root/etc/mdadm.conf $tmpdir/etc/
cp -ar $root/etc/modprobe.* $root/etc/ld-* $tmpdir/etc/ 2>/dev/null || true

# in theory all, but fat and not all always needed ...
cp -a $root/lib/udev/{ata,scsi,cdrom}_id $tmpdir/lib/udev/

elf_magic () {
	readelf -h "$1" | grep 'Machine\|Class'
}

# copy dynamic libraries, and optional plugins, if any.
#
extralibs="`ls $root/{lib*/libnss_files,usr/lib*/libgcc_s}.so* 2> /dev/null`"

copy_dyn_libs () {
	local magic
	# we can not use ldd(1) as it loads the object, which does not work on cross builds
	for lib in $extralibs `readelf -de $1 |
		sed -n -e 's/.*Shared library.*\[\([^]\]*\)\]/\1/p' \
		       -e 's/.*Requesting program interpreter: \([^]]*\)\]/\1/p'`
	do
		# remove $root prefix from extra libs
		[ "$lib" != "${lib#$root/}" ] && lib="${lib##*/}"

		if [ -z "$magic" ]; then
			magic="$(elf_magic $1)"
			[[ $1 = *bin/* ]] && echo "Warning: $1 is dynamically linked!"
		fi
		for libdir in $root/lib*/ $root/usr/lib*/ "$root"; do
			if [ -e $libdir$lib ]; then
			    [ "$magic" != "$(elf_magic $libdir$lib)" ] && continue
			    xlibdir=${libdir#$root}
			    echo "	${1#$root} NEEDS $xlibdir$lib"

			    if [ "${added["$xlibdir$lib"]}" != 1 ]; then
				added["$xlibdir$lib"]=1

				mkdir -p $tmpdir$xlibdir
				while local x=`readlink $libdir$lib`; [ "$x" ]; do
					echo "	$xlibdir$lib SYMLINKS to $x"
					local y=$tmpdir$xlibdir$lib
					mkdir -p ${y%/*}
					ln -sfv $x $tmpdir$xlibdir$lib
					if [ "${x#/}" == "$x" ]; then # relative?
						# directory to prepend?
						[ ${lib%/*} != "$lib" ] && x="${lib%/*}/$x"
					fi
					lib="$x"
				done
				local y=$tmpdir$xlibdir$lib
				mkdir -p ${y%/*}
				cp -af $libdir$lib $tmpdir$xlibdir$lib

				copy_dyn_libs $libdir$lib
			    fi
			fi
		done
	done
}

# setup programs
#
for x in $root/sbin/{udevd,udevadm,kmod,modprobe,insmod,blkid} \
         $root/usr/sbin/disktype
do
	cp -av $x $tmpdir/sbin/
	copy_dyn_libs $x
done

# setup optional programs
#
[ "$minimal" != 1 ] &&
for x in $root/sbin/{vgchange,lvchange,lvm,mdadm} \
	 $root/usr/sbin/cryptsetup $root/usr/embutils/dmesg
do
  if [ ! -e $x ]; then
	echo "Warning: Skipped optional file ${x#$root}!"
  else
	cp -a $x $tmpdir/sbin/
	copy_dyn_libs $x
  fi
done

# copy a small shell
for sh in $root/bin/{pdksh,bash}; do
    if [ -e "$sh" ]; then
	cp $sh $tmpdir/bin/${sh##*/}
	ln -sf ${sh##*/} $tmpdir/bin/sh
	break
    fi
done

# static, tiny embutils and friends
#
cp $root/usr/embutils/{mount,umount,rm,mv,mkdir,ln,ls,switch_root,chroot,sleep,losetup,chmod,cat,sed,mknod} \
   $tmpdir/bin/
ln -s mv $tmpdir/bin/cp

cp $root/sbin/initrdinit $tmpdir/init

# Custom ACPI DSDT table
if test -f "$root/boot/DSDT.aml"; then
	echo "Adding local DSDT file: $dsdt"
	cp $root/boot/DSDT.aml $tmpdir/DSDT.aml
fi

# create the cpio image
#
echo "Archiving ..."
( cd $tmpdir
  find . | cpio -o -H newc | zstd -19 -T0 > $root/boot/initrd-$kernelver
)
rm -rf $tmpdir $map
