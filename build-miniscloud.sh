#!/usr/bin/env bash

#  Copyright 2024-2026 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

for_each_build_script() {
    local scripts=(
        "build-firmware-MGP1WSB.sh"
        "build-kernel.sh"
        "build-vpu_driver.sh"
        "build-npu-driver.sh"
        "build-csidma-driver.sh"
        "build-isp-driver.sh"
        "build-gpu-driver.sh"
        "build-gstreamer.sh"
        "build-tool.sh"
        "build-prideb.sh"
        "build-cix-env.sh"
        "build-cix-common-misc.sh"
        "build-cix-grubcfg.sh"
        "build-vpu_test.sh"
        "build-debian.sh"
        "build-storage.sh"
    )

    local script
    for script in "${scripts[@]}" ; do
        "$SCRIPT_DIR/$script" -n -d "$BUILD_MODE" -p "$PLATFORM" -f "$FILESYSTEM" -h "$SOC_TYPE" -b "$BOARD" -k "$KEY_TYPE" -t "$TEE_TYPE" -r "$DDR_MODEL" -s "$SMP" -a "$ACPI" -x "$NEXUS_SITE" -o "$DEBIAN_MODE" -l "$FASTBOOT_LOAD" -e "$DRM" -w "$NETWORK" -K "$DOCKER_MODE" "$@" || exit 1
    done
}

readonly DO_DESC_build="build all modules"
do_build() {
    if [[ -e "${PATH_ROOT}/output" ]]; then
        cp -drfp "${PATH_ROOT}/ext/output" "${PATH_ROOT}"
    fi
    if [[ -e "${PATH_ROOT}/out" ]]; then
        cp -drfp "${PATH_ROOT}/ext/out" "${PATH_ROOT}"
    fi
    for_each_build_script build
}

readonly DO_DESC_clean="clean all modules"
do_clean() {
    for_each_build_script clean
    if [[ -e "${PATH_ROOT}/output" ]]; then
        sudo rm -rf "${PATH_ROOT}/output"
    fi
    if [[ -e "${PATH_ROOT}/out" ]]; then
        sudo rm -rf "${PATH_ROOT}/out"
    fi
}

if [[ ! -e "${PATH_ROOT}/ext" ]]; then
    cd "${PATH_ROOT}/build-scripts"
    if [[ "$(git remote -v | grep "github.com")X" != "X" ]]; then
        echo -e "${RED}Error: resources (ext) are absent. please download them from github first.${NORMAL}"
        exit 1
    fi
    cd -

    source "${PATH_ROOT}/build-scripts/envtool.sh"
    export EX_CUSTOMER="miniscloud"
    export EX_PROJECT="pc001"
    export EX_VERSION="202603"
    updateres
fi

if [[ ! -e "${PATH_ROOT}/ext" ]]; then
    echo -e "${RED}Error: resources (ext) are absent. maybe doing next can help you.${NORMAL}"
cat <<EOF
source ./build-scripts/envtool.sh
updateres
EOF
    exit 1
fi

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"

