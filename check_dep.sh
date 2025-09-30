#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# return
# exit code 0  - no dependency missing
# exit code !0 - dependency missing or unable to check

DEPS_debian=(
    "autoconf"
    "autopoint"
    "bc"
    "bison"
    "build-essential"
    "cpio"
    "curl"
    "device-tree-compiler"
    "dosfstools"
    "doxygen"
    "fdisk"
    "flex"
    "gdisk"
    "gettext-base"
    "git"
    "libncurses5"
    "libssl-dev"
    "libtinfo5"
    "m4"
    "mtools"
    "pkg-config"
    "python2"
    "python3"
    "python3-distutils"
    "python3-pyelftools"
    "python3-mako"
    "rsync"
    "snapd"
    "unzip"
    "uuid-dev"
    "wget"
    "scons"
    "perl"
    "libwayland-dev"
    "wayland-protocols"
    "indent"
    "libtool"
    "dwarves"
    "libarchive-tools"
    "xorriso"
    "jigdo-file"
    "golang"
    "libffi-dev"
    "u-boot-tools"
    "img2simg"
    "libxcb-randr0"
    "libxcb-randr0-dev"
    "libxcb-present-dev"
    "libxau-dev"
    "libglib2.0-dev-bin"
    "debhelper"
    "jq"
    "pigz"
    "kmod"
    "uuid-runtime"
)

DEPS_android=(
    "gnupg"
    "flex"
    "bison"
    "build-essential"
    "zip"
    "curl"
    "zlib1g-dev"
    "gcc-multilib"
    "g++-multilib"
    "libc6-dev-i386"
    "libncurses5"
    "lib32ncurses-dev"
    "x11proto-core-dev"
    "libx11-dev"
    "lib32z1-dev"
    "libgl1-mesa-dev"
    "libxml2-utils"
    "xsltproc"
    "unzip"
    "fontconfig"
    "python3"
    "python3-pip"
    "git"
    "libssl-dev"
    "liblz4-tool"
)

if ! command -v lsb_release ; then
    echo "ERROR: Unable to check dependencies due to missing command 'lsb_release'!" >&2
    exit 1
fi

function cmd_exists() { if command -v $1 > /dev/null; then echo 1; else echo 0; fi }
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

#param 1: command name (meson)
#param 2: min version (0.59)
#param 3: install script (pip3 install meson)
#get the verison only with "$cmd --version", else the owner does the check.
function checkVersion() {
    local cmd=$1
    local minVersion=$2
    local comment=$3
    if [[ $(cmd_exists "${cmd}") == "0" ]]; then
        echo -e "\e[33m${cmd}\e[31m does not exist\e[0m"
        echo "Install it with this commands:"
        echo -e "${comment}"
    fi
    local ver=$("${cmd}" --version)
    if version_lt $ver "${minVersion}"; then
        echo -e "\e[31mYour \e[33m${cmd}\e[31m version \e[32m${ver}\e[31m is too low (must >= \e[32m${minVersion}\e[0m)"
        echo -e "\e[31mPlease upgrade \e[33m${cmd}\e[0m with"
        echo -e "${comment}"
    fi
}

DIST_INFO=( $(lsb_release -ics) )
DISTRIBUTION="${DIST_INFO[0],,}"
CODENAME="${DIST_INFO[1],,}"
case "$DISTRIBUTION" in
("ubuntu" | "debian")
    if [[ x$(echo $FILESYSTEM) = "x" ]]; then
        deps=(${DEPS_debian[@]} ${DEPS_android[@]})
    else
        case "$FILESYSTEM" in
        ("debian")
            deps=(${DEPS_debian[@]})
            ;;
        ("android")
            deps=(${DEPS_android[@]})
            ;;
        (*)
            deps=(${DEPS_debian[@]})
            ;;
        esac
    fi
    for dep in ${deps[@]}; do
        if ! LC_ALL=C dpkg-query --show -f='${Status}\n' "$dep" 2>/dev/null  | grep -qE '([[:blank:]]|^)installed([[:blank:]]|$)' ; then
            echo "$dep"
        fi
    done \
    | sort \
    | {
        mapfile -t missing_deps
        if [[ "${#missing_deps[@]}" -ne 0 ]] ; then
            echo "The following packages was detected as missing:"
            for s in "${missing_deps[@]}" ; do
                echo "  * $s"
            done
            #sudo apt-get install "${missing_deps[@]}"
            echo
            echo "Install them with this commands:"
            echo "sudo apt-get install" "${missing_deps[@]}"
            exit 1
        fi
    }
    ;;
(*)
    echo "ERROR: Unknown distribution, can not check dependencies!" >&2
    exit 1
esac
echo "no missing dependencies detected."

if [[ x$(echo $FILESYSTEM) != "x" ]]; then
    case "$FILESYSTEM" in
    ("debian")
        echo "check the depends' version for linux"
        pip3 show -q ply || pip3 install ply
        checkVersion meson 1.3.0 "pip3 install --upgrade --force-reinstall 'meson==1.3.0'"
        pip3 --default-timeout=100 install openpyxl -i https://pypi.tuna.tsinghua.edu.cn/simple
        ;;
    ("android")
        echo "check the depends' version for android"
        ;;
    (*)
        echo "check the depends' version for none os"
        ;;
    esac
fi
