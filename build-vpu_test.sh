#!/usr/bin/env bash

#  Copyright 2025 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-vpu_driver.sh"

readonly DO_DESC_build="build linux vpu unit test and embed into debian system"
do_build() {

    # build deb package
    pkg_Name="cix-vpu-test"
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/usr/share/cix/bin
    mkdir -p $install_dir

    UNIT_TEST_PATH=${PATH_ROOT}/component/cix_opensource/cix_unit_test

    export KDIR=${PATH_LINUX}
    cd ${UNIT_TEST_PATH}/cix_vpu_test
    scons
    cp bin/aarch64-none-linux-gnu/* ${install_dir}
    cd -

    create_cix_deb "${pkg_Name}"
    # finish build deb package

}

readonly DO_DESC_clean="clean linux vpu unit test"
do_clean() {
    UNIT_TEST_PATH=${PATH_ROOT}/component/cix_opensource/cix_unit_test

    ### Clean VPU Unit Test
    cd ${UNIT_TEST_PATH}/cix_vpu_test
    ./clean.sh
    cd -
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
