#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build isp driver and embed into debian system"
do_build() {
    export ARCH=arm64
    export DRV_DIR=${PATH_ROOT}/linux/drivers/media/platform/cix/cix_isp
    export KSRC=${PATH_LINUX}
    MODULE=armcb_isp

    cd "${DRV_DIR}"
    echo -e "Build isp driver..."

    if [ -f ${DRV_DIR}/${MODULE}.ko ]; then
        # build deb package
        pkg_Name="cix-isp-driver"
        build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
        rm -rf ${build_deb_dir}
        install_dir=${build_deb_dir}/lib/modules/${linux_version}/extra
        mkdir -p ${install_dir}
        cp ${DRV_DIR}/${MODULE}.ko ${install_dir}
        create_cix_deb "${pkg_Name}"
        # finish build deb package
    else
        echo error ${MODULE}.ko module not exist
        exit
    fi
}

readonly DO_DESC_clean="clean isp driver project"
do_clean() {
    local KMD_DRV_DIR=${PATH_ROOT}/linux/drivers/media/platform/cix/cix_isp
    make -C "${KMD_DRV_DIR}" clean
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
