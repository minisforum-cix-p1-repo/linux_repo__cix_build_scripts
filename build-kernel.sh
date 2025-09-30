#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

function disablePCIE() {
    local path_dts="${PATH_ROOT}/${PLAT_PREFIX}linux/arch/arm64/boot/dts/cix/sky1-evb.dts"
    #replace_line_offset_lines "&its_pcie" "\	status = \"disabled\";" "1" "${path_dts}"
    replace_line_offset_lines "&pcie0_rc" "\	status = \"disabled\";" "5" "${path_dts}"
    replace_line_offset_lines "&pcie1_rc" "\	status = \"disabled\";" "5" "${path_dts}"
    replace_line_offset_lines "&pcie2_rc" "\	status = \"disabled\";" "5" "${path_dts}"
    replace_line_offset_lines "&pcie3_rc" "\	status = \"disabled\";" "5" "${path_dts}"
    replace_line_offset_lines "&pcie4_rc" "\	status = \"disabled\";" "5" "${path_dts}"

    #replace_line_offset_lines "CONFIG_GPIO_PL061" "# obj-\$(CONFIG_GPIO_PL061)		+= gpio-pl061.o" "0" "${PATH_ROOT}/${PLAT_PREFIX}linux/drivers/gpio/Makefile"
}

readonly DO_DESC_build="build kernel"
do_build() {
    #disablePCIE
    local path_kernel="${PATH_ROOT}/${PLAT_PREFIX}linux"
    local config_file
    local target
    case "$PLATFORM" in
    ("cix")
        config_file="defconfig cix.config"
        if [[ "${DOCKER_MODE}" == "docker" ]]; then
            config_file="${config_file} cix_redroid.config"
        fi
        if [[ "$BUILD_MODE" == "debug" ]]; then
            config_file="${config_file} cix_debug.config"
        fi
        target="dtbs Image"
        ;;
    (*)
        config_file="defconfig cix.config"
        target="dtbs Image"
        ;;
    esac

    if [[ $(check_compile "${path_kernel}" "" "${PATH_OUT}/Image") == "false" ]]; then
        return 0
    fi
    # if [[ "${ISO_INSTALLER}" == "1" ]]; then
    #     replace_line_offset_lines "drm_fbdev_generic_setup(" "        drm_fbdev_generic_setup(&mdrv->kms->base, 32);" "0" "${path_kernel}/drivers/gpu/drm/cix/linlon-dp/linlondp_drv.c"
    # fi
    case "$BOARD" in
    ("cloudbook")
        if [ -f "$path_kernel/arch/arm64/configs/cix_cloudbook.config" ]; then
            config_file="${config_file} cix_cloudbook.config"
        fi
        ;;
    ("emu")
        if [ -f "$path_kernel/arch/arm64/configs/cix_emu.config" ]; then
            config_file="${config_file} cix_emu.config"
        fi
        ;;
    ("fpga")
        if [ -f "$path_kernel/arch/arm64/configs/cix_fpga.config" ]; then
            config_file="${config_file} cix_fpga.config"
        fi
        ;;
    (*)
        ;;
    esac

    rm -f "${PATH_ROOT}"/linux-*
    rm -f "${PATH_OUT}"/linux-*

    mkdir -p "${PATH_SYSROOT}/etc"
    mkdir -p "${PATH_SYSROOT}/lib"
    mkdir -p "${PATH_SYSROOT}/lib64"
    mkdir -p "${PATH_SYSROOT}/sbin"
    mkdir -p "${PATH_SYSROOT}/usr"
    mkdir -p "${PATH_SYSROOT}/var"
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/etc/* "${PATH_SYSROOT}"/etc
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/lib/* "${PATH_SYSROOT}"/lib
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/lib64/* "${PATH_SYSROOT}"/lib64
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/sbin/* "${PATH_SYSROOT}"/sbin
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/usr/* "${PATH_SYSROOT}"/usr||true
    cp -rf "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/aarch64-none-linux-gnu/libc"/var/* "${PATH_SYSROOT}"/var

    cd $path_kernel
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" ${config_file}
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" $target -j${PARALLELISM}
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" modules -j${PARALLELISM}
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" headers_install INSTALL_HDR_PATH="${PATH_SYSROOT}"
    if [[ $INPUT != "nodeb" ]]; then
        rm -rf $PATH_DEB/linux*.deb
        make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" ${config_file} bindeb-pkg -j${PARALLELISM}
        rm -rf $PATH_ROOT/linux-upstream*
        mv -f $PATH_ROOT/linux*.deb $PATH_DEB
        if [[ -e "${PATH_ROOT}/build-scripts/debian/dkms/linux/scripts" ]]; then
            if [[ -e "${PATH_OUT}/debs_tmp/linux-headers" ]]; then
                rm -rf "${PATH_OUT}/debs_tmp/linux-headers"
            fi
            mkdir "${PATH_OUT}/debs_tmp/linux-headers"
            local def_file=$(ls ${PATH_DEB}/linux-headers*.deb)
            dpkg-deb -R "${def_file}" "${PATH_OUT}/debs_tmp/linux-headers"
            cp -rfp ${PATH_ROOT}/build-scripts/debian/dkms/linux/scripts/* ${PATH_OUT}/debs_tmp/linux-headers/usr/src/linux-headers-*/scripts/
            dpkg-deb -b --root-owner-group "${PATH_OUT}/debs_tmp/linux-headers" "${def_file}"
        fi
    fi
    cd -

    case "$PLATFORM" in
    ("cix")
        cp -f "${path_kernel}/arch/arm64/boot/dts/cix"/*.dtb "${PATH_OUT}/"
        ;;
    esac

    cp -f "${path_kernel}/arch/arm64/boot/Image" "${PATH_OUT}/"

    record_compile "${path_kernel}"
}

readonly DO_DESC_clean="clean kernel"
do_clean() {
    local path_kernel="${PATH_ROOT}/${PLAT_PREFIX}linux"

    cd "${path_kernel}"
    make distclean
    rm -f "${PATH_OUT}/Image"
    rm -f "${PATH_OUT}"/*.dtb
    rm -rf $PATH_ROOT/linux-upstream*
    rm -rf $PATH_ROOT/*.deb
    cd -
}

readonly DO_DESC_dts="build dts"
do_dts() {
    local path_kernel="${PATH_ROOT}/${PLAT_PREFIX}linux"
    local config_file
    local target
    case "$PLATFORM" in
    ("cix")
        config_file="defconfig cix.config"
        if [[ "$BUILD_MODE" == "debug" ]]; then
            config_file="${config_file} cix_debug.config"
        fi
        target="dtbs"
        ;;
    (*)
        config_file="defconfig cix.config"
        target="dtbs"
        ;;
    esac

    case "$BOARD" in
    ("emu")
        if [ -f "$path_kernel/arch/arm64/configs/cix_emu.config" ]; then
            config_file="${config_file} cix_emu.config"
        fi
        ;;
    ("fpga")
        if [ -f "$path_kernel/arch/arm64/configs/cix_fpga.config" ]; then
            config_file="${config_file} cix_fpga.config"
        fi
        ;;
    (*)
        ;;
    esac

    cd $path_kernel
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" ${config_file}
    make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" $target -j${PARALLELISM}
    cd -

    cp -f "${path_kernel}/arch/arm64/boot/dts/cix"/*.dtb "${PATH_OUT}/"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
