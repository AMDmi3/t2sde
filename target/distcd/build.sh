# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/distcd/build.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
source misc/target/functions
[ -f target/$target/functions ] && source target/$target/functions

#rm -rf $imagedir
#mkdir -p $imagedir

image_parse_cfg target/$target/initrd.cfg
exit

pkgsel_update_tmpl   # rerun config if pkgsel.tmpl was updated
pkgloop              # build it

# bend PATH so we use utils we build ourselves
export PATH="$build_rock/tools.cross/bin:$base/build/${ROCKCFG_ID}/TOOLCHAIN/tools.cross/diet-bin:$PATH"
# set DIETHOME in case we use diet
export DIETHOME="$base/build/${ROCKCFG_ID}/usr/dietlibc"

# 








# Create ISO structure
#iso_prepare_bootable
#FIXME dummy entry
#iso_add DISK1 $topdir/COPYING /
