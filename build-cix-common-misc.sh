#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

do_build() {
    pkg_Name="cix-common-misc"
    cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
    create_cix_deb "${pkg_Name}"

    if [ $DEBIAN_MODE == 7 ]; then
        pkg_Name="cix-openkylin-adapter"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"

    elif [ $DEBIAN_MODE == 6 ]; then
        pkg_Name="cix-deepin-adapter"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"

    elif [ "$DEBIAN_MODE" == "5" -o "$DEBIAN_MODE" == "8" ]; then
        pkg_Name="cix-openkylin-beta2"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        create_cix_deb "${pkg_Name}"
    else
        pkg_Name="cix-debian-misc"
        cp -r $PATH_SOURCE_DEB/$pkg_Name ${PATH_OUT_DEB_PACKAGES}
        if [[ "${DOCKER_MODE}" == "docker" ]]; then
            if [[ ! -e "${PATH_OUT_DEB_PACKAGES}/${pkg_Name}/usr/lib/systemd/system/cix-docker-env.service" ]]; then
                echo "error, miss cix-docker-env.service!"
                exit 1
            fi
        else
            rm -f ${PATH_OUT_DEB_PACKAGES}/${pkg_Name}/usr/lib/systemd/system/cix-docker-env.service
        fi
        create_cix_deb "${pkg_Name}"
    fi
}
do_clean() {
    rm -rf ${PATH_DEB}/cix-common-misc*.deb
}
source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
