# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by scripts/Create-CopyPatch.
# 
# T2 SDE: architecture/arm/archtest.sh
# Copyright (C) 2007 - 2021 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

case "$SDECFG_ARM_ENDIANESS" in
	eb)
		arch_bigendian=yes
		arch_machine=armeb ;;
		
	*)
		arch_bigendian=no
		arch_machine=arm ;;
esac

[ "$arch_bigendian" = no ] &&
case "$SDECFG_ARM_OPT" in
	arm7*)
		arch_machine=${arch_machine}v4 ;;
	arm[89]*|arm10*)
		arch_machine=${arch_machine}v5 ;;
	arm11*)
		arch_machine=${arch_machine}v6 ;;
	*)
		arch_machine=${arch_machine}v7 ;;
esac

arch_target="${arch_machine}-t2-linux-${SDECFG_ARM_ABI}"
