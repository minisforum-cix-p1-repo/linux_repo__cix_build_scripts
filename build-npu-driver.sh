#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build npu driver and embed into debian system"
do_build() {
    pkg_Name="cix-npu-driver"
    if [[ $(check_compile "${PATH_ROOT}/component/cix_opensource/npu/npu_driver" "" "${PATH_DEB}/${pkg_Name}_*.deb") == "false" ]]; then
        return 0
    fi
export COMPASS_DRV_BTENVAR_ARCH=arm64
export COMPASS_DRV_BTENVAR_KMD_DIR=driver

export COMPASS_DRV_BTENVAR_KMD_VERSION=5.10.0
export COMPASS_DRV_BTENVAR_KPATH=${PATH_LINUX}
export BUILD_AIPU_VERSION_KMD=BUILD_ZHOUYI_V3
export BUILD_TARGET_PLATFORM_KMD=BUILD_PLATFORM_SKY1
export BUILD_NPU_DEVFREQ=y

cd "${PATH_ROOT}/component/cix_opensource/npu/npu_driver"
cp -f ${COMPASS_DRV_BTENVAR_KMD_DIR}/armchina-npu/include/armchina_aipu.h ${PATH_LINUX}/include/uapi/misc

echo -e "Build KMD..."
make -j$PARALLELISM -C ${COMPASS_DRV_BTENVAR_KMD_DIR} ARCH=${COMPASS_DRV_BTENVAR_ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j${PARALLELISM}

if [ -f ${COMPASS_DRV_BTENVAR_KMD_DIR}/aipu.ko ]; then
    # build deb package
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/lib/modules/${linux_version}/extra
    mkdir -p ${install_dir}
    cp ${COMPASS_DRV_BTENVAR_KMD_DIR}/aipu.ko ${install_dir}
    create_cix_deb "${pkg_Name}"
    # finish build deb package
fi
rm -f $PATH_LINUX/include/uapi/misc/armchina_aipu.h

cd -
    record_compile "${PATH_ROOT}/component/cix_opensource/npu/npu_driver"
}

readonly DO_DESC_clean="clean npu driver project"
do_clean() {
export COMPASS_DRV_BTENVAR_KPATH=${PATH_LINUX}
cd "${PATH_ROOT}/component/cix_opensource/npu/npu_driver/driver"
make clean||true
cd -
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
