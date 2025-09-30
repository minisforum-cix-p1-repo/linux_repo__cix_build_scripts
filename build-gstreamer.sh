#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
# Gstreamer Revision: original 1.20.2


DEPENDENT_MODULES="build-vpu_driver.sh"

readonly DO_DESC_build="build gstreamer into debian system"

cross_env() {
    echo '[binaries]' > cross_env.txt
    echo "c = '$CC'" >> cross_env.txt
    echo "cpp = '$CXX'" >> cross_env.txt
    echo "ar = '$AR'" >> cross_env.txt
    echo "ld = '$LD'" >> cross_env.txt
    echo "strip = '$STRIP'" >> cross_env.txt
    echo "pkg-config = 'pkg-config'" >> cross_env.txt

    echo '[host_machine]' >> cross_env.txt
    echo "system = 'linux'" >> cross_env.txt
    echo "cpu_family = 'aarch64'" >> cross_env.txt
    echo "cpu = 'aarch64'" >> cross_env.txt
    echo "endian = 'little'" >> cross_env.txt

    echo '[properties]' >> cross_env.txt
    echo "sys_root = '${PATH_SYSROOT}'" >> cross_env.txt
    echo "pkg_config_libdir = '${PATH_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${PATH_SYSROOT}/lib/pkgconfig:${PATH_SYSROOT}/usr/share/pkgconfig:${PATH_SYSROOT}/usr/lib/pkgconfig'" >> cross_env.txt

    echo '[built-in options]' >> cross_env.txt
    echo "c_args = ['--sysroot', '${PATH_SYSROOT}', '-I${PATH_SYSROOT}/usr/include/aarch64-linux-gnu', '-I${PATH_EXPORT_INCLUDE}']" >> cross_env.txt
    echo "cpp_args = ['--sysroot', '${PATH_SYSROOT}', '-I${PATH_SYSROOT}/usr/include/aarch64-linux-gnu', '-I${PATH_EXPORT_INCLUDE}']" >> cross_env.txt
}

construct_deb_pkg() {
    mkdir -p ${install_dir}/lib/gstreamer-1.0/
    local gst_libs=(
        "libgstaudio-1.0.so*"
        "libgstvideo-1.0.so*"
        "libgstcixdspif.so"
    )
    local gst_plugins=(
        "libgstafbcparse.so"
        "libgstcixheaacv2enc.so"
        "libgstcixmp3dec.so"
        "libgstcixsr.so"
        "libgstcoreelements.so"
        "libgstfdkaac.so"
        "libgstgtk.so"
        "libgstkms.so"
        "libgstopengl.so"
        "libgstvideo4linux2.so"
    )
    local lib
    for lib in "${gst_libs[@]}" ; do
        cp -a ${install_dir_tmp}/lib/$lib ${install_dir}/lib/
    done
    for lib in "${gst_plugins[@]}" ; do
        cp -a ${install_dir_tmp}/lib/gstreamer-1.0/$lib ${install_dir}/lib/gstreamer-1.0/
    done
    rm -rf ${install_dir_tmp}
}

do_build() {
    export CROSS_COMPILE="${CROSS_COMPILE_EXTRA}"
    export CC="${CROSS_COMPILE}gcc"
    export AR="${CROSS_COMPILE}ar"
    export CXX="${CROSS_COMPILE}g++"
    export LD="${CROSS_COMPILE}ld"
    export STRIP="${CROSS_COMPILE}strip"
    export ARCH=arm64
    export PKG_CONFIG_PATH=
    export LD_LIBRARY_PATH=${PATH_EXPORT_LIB}

    path_gst="${PATH_ROOT}/component/cix_opensource/gstreamer/"
    pkg_Name="cix-gstreamer"
    if [[ $(check_compile "${path_gst}" "" "${PATH_DEB}/${pkg_Name}_*.deb") == "false" ]]; then
        return 0
    fi

    cd "${path_gst}"
    cross_env

    export LD_LIBRARY_PATH="${PATH_SYSROOT}/usr/share/cix/lib:${PATH_SYSROOT}/usr/lib/aarch64-linux-gnu"
    export GST_PLUGIN_PATH="${PATH_SYSROOT}/usr/share/cix/lib"
    export GST_PLUGIN_PATH_1_0="${PATH_SYSROOT}/usr/share/cix/lib/gstreamer-1.0"
    export GST_PLUGIN_SCANNER="${PATH_SYSROOT}/usr/share/cix/libexec/gstreamer-1.0/gst-plugin-scanner"
    # build deb package
    build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    rm -rf ${build_deb_dir}
    install_dir=${build_deb_dir}/usr/share/cix
    install_dir_tmp=${build_deb_dir}/usr/share/cix_tmp
    mkdir -p ${install_dir}
    mkdir -p ${install_dir_tmp}

    meson setup --prefix="$install_dir_tmp" \
        --cross-file="${path_gst}cross_env.txt" \
        --strip -Dauto_features=disabled \
        --wrap-mode=nodownload \
        -Dbase=enabled \
        -Dgood=enabled \
        -Dbad=enabled \
        -Dgst-plugins-base:gl=enabled \
        -Dgst-plugins-good:v4l2=enabled \
        -Dgst-plugins-good:gtk3=enabled \
        -Dgst-plugins-bad:kms=enabled \
        -Dgst-plugins-bad:fdkaac=enabled \
	"${path_gst}build"
    ninja -C "${path_gst}build"
    meson install -C "${path_gst}build"
    construct_deb_pkg
    create_cix_deb "${pkg_Name}"
    # finish build deb package

    cd -
    record_compile "${path_gst}"
}

readonly DO_DESC_clean="clean gstreamer"
do_clean() {
    export CROSS_COMPILE="${CROSS_COMPILE_EXTRA}"
    export CC="${CROSS_COMPILE}gcc"
    export AR="${CROSS_COMPILE}ar"
    export CXX="${CROSS_COMPILE}g++"
    export LD="${CROSS_COMPILE}ld"
    export ARCH=arm64

    path_gst="${PATH_ROOT}/component/cix_opensource/gstreamer/"

    cd "${path_gst}"
    if [[ -e "${path_gst}build/build.ninja" ]] && [[ -e "${path_gst}cross_env.txt" ]]; then
        ninja clean -C "${path_gst}build"
        rm -f "${path_gst}cross_env.txt"
        rm -rf "${path_gst}build"
    fi
    if [[ -e "build" ]]; then
        rm -rf "build"
    fi
    cd -
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
