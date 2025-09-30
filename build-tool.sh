#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#

readonly DO_DESC_build="build tools"
do_build() {
    # build deb package
    pkg_Name="cix-tools"
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/usr/share/cix/bin
    mkdir -p ${install_dir}
    cp -rf ${PATH_ROOT}/tools/cix_binary/device/misc/* ${build_deb_dir}
    rm -rf $install_dir/i3ctransfer
    rm -rf $install_dir/spidev_fdx
    rm -rf $install_dir/uart_test
    create_cix_deb "${pkg_Name}"
    # finish build deb package

}

readonly DO_DESC_clean="clean tools"
do_clean() {
    echo "nothing to do"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
