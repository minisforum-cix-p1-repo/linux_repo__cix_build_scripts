#!/usr/bin/env bash

export  BOLD="\e[1m"
export  NORMAL="\e[0m"
export	RED="\e[31m"
export	GREEN="\e[32m"
export	YELLOW="\e[33m"
export  BLUE="\e[94m"
export  CYAN="\e[36m"

readonly DO_DESC_build="build uefi"
do_build() {
    set +u
    local path_uefi="${PATH_ROOT}/bsp/uefi_release"
    local open_firmwre_build_script="${path_uefi}/edk2-non-osi/Platform/CIX/Sky1/PackageTool/build_and_package.sh"
    local package_internal_binary_script="${PATH_ROOT}/bsp/cix_bsp_release/package_internal_flash_binary.sh"
    local UEFI_PROJECT="MGP1WSB"

    cd "${path_uefi}"

    if [[ ! -e "${open_firmwre_build_script}" ]]; then
        echo -e "${RED}There is no ${open_firmwre_build_script}!${NORMAL}"
        exit 1
    fi

    ${open_firmwre_build_script} ${UEFI_PROJECT}

    if [[ ! -e "${path_uefi}/output/cix_flash_all.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all.bin failed!${NORMAL}"
    fi

    if [[ ! -e "${path_uefi}/output/cix_flash_ota.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota.bin failed!${NORMAL}"
    fi

    cp "${path_uefi}/output/cix_flash_all.bin" "${PATH_OUT}/images/cix_flash_all_${UEFI_PROJECT}.bin"
    cp "${path_uefi}/output/cix_flash_ota.bin" "${PATH_OUT}/images/cix_flash_ota_${UEFI_PROJECT}.bin"

    if [[ ! -e "${path_uefi}/output/cix_flash_all2.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all2.bin failed!${NORMAL}"
    fi

    if [[ ! -e "${path_uefi}/output/cix_flash_ota2.bin" ]]; then
        echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota2.bin failed!${NORMAL}"
    fi

    cp "${path_uefi}/output/cix_flash_all2.bin" "${PATH_OUT}/images/cix_flash_all2_${UEFI_PROJECT}.bin"
    cp "${path_uefi}/output/cix_flash_ota2.bin" "${PATH_OUT}/images/cix_flash_ota2_${UEFI_PROJECT}.bin"

    cp "${path_uefi}/output/cix_flash_all2.bin" "${PATH_OUT}/images/cix_flash_all_rsa_pr2_${UEFI_PROJECT}.bin"
    cp "${path_uefi}/output/cix_flash_ota2.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_pr2_${UEFI_PROJECT}.bin"

    if [[ -e "${package_internal_binary_script}" ]]; then
        ${package_internal_binary_script}

        # product key1 debug image
        if [[ ! -e "${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin failed!${NORMAL}"
        fi

        if [[ ! -e "${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin failed!${NORMAL}"
        fi

        cp "${path_uefi}/output/cix_flash_all_rsa_pr_debug.bin" "${PATH_OUT}/images/cix_flash_all_rsa_pr_debug_${UEFI_PROJECT}.bin"
        cp "${path_uefi}/output/cix_flash_ota_rsa_pr_debug.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_pr_debug_${UEFI_PROJECT}.bin"

        # product key2 debug image
        if [[ ! -e "${path_uefi}/output/cix_flash_all_rsa_pr2_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_all_rsa_pr2_debug.bin failed!${NORMAL}"
        fi

        if [[ ! -e "${path_uefi}/output/cix_flash_ota_rsa_pr2_debug.bin" ]]; then
            echo -e "${RED}Generate ${path_uefi}/output/cix_flash_ota_rsa_pr2_debug.bin failed!${NORMAL}"
        fi

        cp "${path_uefi}/output/cix_flash_all_rsa_pr2_debug.bin" "${PATH_OUT}/images/cix_flash_all_rsa_pr2_debug_${UEFI_PROJECT}.bin"
        cp "${path_uefi}/output/cix_flash_ota_rsa_pr2_debug.bin" "${PATH_OUT}/images/cix_flash_ota_rsa_pr2_debug_${UEFI_PROJECT}.bin"

    fi

    echo -e "${GREEN}Generate ${PATH_OUT}/images/cix_flash_all.bin successful!${NORMAL}"

    cd -
}

readonly DO_DESC_clean="clean uefi"
do_clean() {
    echo "clean uefi"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
