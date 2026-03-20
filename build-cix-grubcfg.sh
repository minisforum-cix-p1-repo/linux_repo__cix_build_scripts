#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"
readonly DO_DESC_build="build cix grub config"

do_build() {
    if [[ "${ISO_INSTALLER:-0}" != "1" ]]; then
        return 0
    fi

    rm -rf $PATH_OUT_DEB_PACKAGES/cix-grubcfg
    cp -r $PATH_SOURCE_DEB/cix-grubcfg ${PATH_OUT_DEB_PACKAGES}
    mkdir -p "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/boot"
    if [[ "${ACPI}" == "0" ]]; then
        cp -pf $PATH_OUT/sky1-${BOARD}.dtb $PATH_OUT_DEB_PACKAGES/cix-grubcfg/boot/sky1.dtb
        #sed -i s/evb/${BOARD}/g $PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/grub.d/09_cix_linux
        replace_or_add_line "GRUB_CMDLINE_LINUX=" "GRUB_CMDLINE_LINUX=\"console=ttyAMA0,115200 efi=noruntime earlycon=pl011,0x040d0000 loglevel=4 arm-smmu-v3.disable_bypass=0 acpi=off\"" "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/default/grub.d/cix_grub.cfg"
     else
        replace_or_add_line "devicetree" "\ " "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/grub.d/09_cix_linux"
        replace_or_add_line "GRUB_CMDLINE_LINUX=" "GRUB_CMDLINE_LINUX=\"console=ttyAMA0,115200 efi=noruntime earlycon=pl011,0x040d0000 loglevel=4 arm-smmu-v3.disable_bypass=0 cma=640M acpi=force\"" "$PATH_OUT_DEB_PACKAGES/cix-grubcfg/etc/default/grub.d/cix_grub.cfg"
    fi
    create_cix_deb cix-grubcfg
}

do_clean() {
  echo "nothing to do"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
