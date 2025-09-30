#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build gpu driver and embed into debian system"
do_build() {
    pkg_Name="cix-gpu-driver"
    gpu_driver_dir=${PATH_ROOT}/component/cix_opensource/gpu/gpu_kernel/drivers
    if [[ $(check_compile "${gpu_driver_dir}" "" "${PATH_DEB}/${pkg_Name}_*.deb") == "false" ]]; then
        return 0
    fi
    export KDIR=${PATH_LINUX}
    export CONFIG_MALI_BASE_MODULES=y
    export CONFIG_MALI_MEMORY_GROUP_MANAGER=y
    export CONFIG_MALI_PROTECTED_MEMORY_ALLOCATOR=y
    export CONFIG_MALI_PLATFORM_NAME="sky1"
    export CONFIG_MALI_CSF_SUPPORT=y
    export CONFIG_MALI_CIX_POWER_MODEL=y

    if [[ "${DOCKER_MODE}" == "docker" ]]; then
        ARCH=arm64 make KCFLAGS="-DUSING_DOCKER_MODE" -j${PARALLELISM} -C ${gpu_driver_dir}/base/arm/
        ARCH=arm64 make KCFLAGS="-DUSING_DOCKER_MODE" -j${PARALLELISM} -C ${gpu_driver_dir}/gpu/arm/
    else
        ARCH=arm64 make -j${PARALLELISM} -C ${gpu_driver_dir}/base/arm/
        ARCH=arm64 make -j${PARALLELISM} -C ${gpu_driver_dir}/gpu/arm/
    fi

    # build deb package
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/lib/modules/${linux_version}/extra
    mkdir -p ${install_dir}
    cp ${gpu_driver_dir}/base/arm/memory_group_manager/memory_group_manager.ko ${install_dir}
    cp ${gpu_driver_dir}/base/arm/protected_memory_allocator/protected_memory_allocator.ko ${install_dir}
    cp ${gpu_driver_dir}/gpu/arm/midgard/mali_kbase.ko ${install_dir}
    create_cix_deb "${pkg_Name}"
    # finish build deb package
    record_compile "${gpu_driver_dir}"
}

readonly DO_DESC_clean="clean gpu driver project"
do_clean() {
    suffixs=".o .ko .cmd .order .mod .mod.c .symvers"
    cd ${PATH_ROOT}/component/cix_opensource/gpu/gpu_kernel/
    for suffix in ${suffixs};do
        for file in $(find -name *${suffix});do
            rm -rf ${file}
        done
    done
    cd -
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
