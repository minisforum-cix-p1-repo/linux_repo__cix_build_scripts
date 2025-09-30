#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build vpu driver and test applications, and embed into debian system"
do_build() {
    pkg_Name="cix-vpu-driver"
    if [[ $(check_compile "${PATH_ROOT}/component/cix_opensource/vpu/vpu_driver" "" "${PATH_DEB}/${pkg_Name}_*.deb") == "false" ]]; then
        return 0
    fi
    export CROSS_COMPILE
    export SYSROOT="${PATH_SYSROOT}"
    export ARCH="arm64"
    export KDIR=${PATH_LINUX}

    cd "${PATH_ROOT}/component/cix_opensource/vpu/vpu_driver"
    scons -j$PARALLELISM target=linux
    # build deb package
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/usr/share/cix/bin
    install_dir_kernel_modules=${build_deb_dir}/lib/modules/${linux_version}/extra
    install_dir_include=${build_deb_dir}/usr/share/cix/include
    install_dir_firmware="${build_deb_dir}/lib/firmware"
    mkdir -p ${install_dir}
    mkdir -p ${install_dir_kernel_modules}
    mkdir -p ${install_dir_include}
    mkdir -p ${install_dir_firmware}
    cp bin/aarch64-none-linux-gnu/amvx.ko ${install_dir_kernel_modules}
    cp include/aarch64-none-linux-gnu/mvx-v4l2-controls.h ${install_dir_include}

    if [[ -d "${PATH_OUT_PRIVATE_DEB_PACKAGES}/cix-vpu-umd/usr/lib/firmware" ]]; then
        cp -fp ${PATH_OUT_PRIVATE_DEB_PACKAGES}/cix-vpu-umd/usr/lib/firmware/* ${install_dir_firmware}/
    fi

    create_cix_deb "${pkg_Name}"
    # finish build deb package
    cp include/aarch64-none-linux-gnu/*.h "${PATH_SYSROOT}/usr/share/cix/include"
    cd -
    record_compile "${PATH_ROOT}/component/cix_opensource/vpu/vpu_driver"
}

readonly DO_DESC_clean="clean vpu driver project"
do_clean() {
    cd "${PATH_ROOT}/component/cix_opensource/vpu/vpu_driver"
    ./clean.sh
    cd -
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
