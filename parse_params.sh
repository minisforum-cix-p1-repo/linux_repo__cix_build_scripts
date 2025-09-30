#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

SOC_TYPE="sky1_a0"
readonly SOC_TYPE_OPTIONS=(
    "sky1_a0"
    "sky1_b1"
)

BOARD="evb"
readonly BOARD_OPTIONS=(
    "emu"
    "fpga"
    "evb"
    "crb"
    "cloudbook"
    "batura"
    "qemu"
)

readonly FILESYSTEM_DEFAULT="debian"
readonly FILESYSTEM_OPTIONS=(
    "debian"
    "android"
    "none"
)

readonly PLATFORM_DEFAULT="cix"
readonly PLATFORM_OPTIONS=(
    "cix"
    "fvp_tc2"
)

NEXUS_SITE="customer"
readonly NEXUS_SITE_OPTIONS=(
    "sh" #shanghai
    "zj" #zhangjiang
    "szv" #suzhou
    "wuh" #wuhan
    "ksh" #kunshan
    "wux" #wuxi
    "release" #release
    "customer" #customer
)

BUILD_MODE="release"
readonly BUILD_MODE_OPTIONS=(
    "release"
    "debug"
)

KEY_TYPE="rsa3072_product"
readonly KEY_TYPE_OPTIONS=(
    "rsa3072_product"
    "sm2_product"
    "rsa3072_prototype"
    "sm2_prototype"
)

KMS="lkms"
readonly KMS_OPTIONS=(
    "lkms"
    "rkms"
)

DRM="disable" #Digital Rights Management: disable, enable
readonly DRM_OPTIONS=(
    "disable"
    "enable"
)

TEE_TYPE="optee"
readonly TEE_TYPE_OPTIONS=(
    "none"
    "optee"
    "trusty"
)

DDR_MODEL="axi-4G"
readonly DDR_MODEL_OPTIONS=(
    "axi-4G"
    "ddr*"
    #"axi-16G" #coming soon
)

SMP="1"
readonly SMP_OPTIONS=(
    "0"
    "1"
)

ACPI="0"
readonly ACPI_OPTIONS=(
    "0"
    "1"
)

DEBIAN_MODE="0"
readonly DEBIAN_MODE_OPTIONS=(
    "0"  #without debian
    "1"  #gnome+xfce
    "4"  #console
    "5"  #openkylin2.0-Release
    "6"  #deepin
    "7"  #openkylin-alpha
    "8"  #kylin-v10-sp1
)

FASTBOOT_LOAD="disable"
readonly FASTBOOT_LOAD_OPTIONS=(
    "disable"
    "ddr"
    "nvme"
    "spi"
    "usb"
)

NETWORK="open"
readonly NETWORK_OPTIONS=(
    "internal"
    "open"
)

DOCKER_MODE="none"
readonly DOCKER_MODE_OPTIONS=(
    "none"
    "docker"
)

DEPENDEE="not dependee"

readonly CMD_DEFAULT=( "build" )
readonly CMD_OPTIONS=( $(compgen -A function | sed -rne 's#^do_##p') )

print_usage() {
    echo -e "${BOLD}Usage:"
    echo -e "    $0 ${CYAN} [-f FILESYSTEM] [-p PLATFORM] [-d BUILD_MODE] [-x NEXUS_SITE] [-j PARALLELISM] [-i INPUT] [-k KEY_TYPE] [-m KMS] [-h SOC_TYPE] [-b BOARD] [-t TEE_TYPE] [-r DDR_MODEL] [-s SMP] [-a ACPI] [-o DEBIAN_MODE] [-l FASTBOOT_LOAD] [-e DRM] [-w NETWORK] [-K DOCKER_MODE] [CMD...]$NORMAL"
    echo
    echo "FILESYSTEM (default is \"$FILESYSTEM_DEFAULT\"):"
    local s
    for s in "${FILESYSTEM_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "PLATFORM (default is \"$PLATFORM_DEFAULT\"):"
    for s in "${PLATFORM_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "SOC_TYPE (default is \"$SOC_TYPE\"):"
    for s in "${SOC_TYPE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "BOARD (default is \"$BOARD\"):"
    for s in "${BOARD_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "NEXUS_SITE (default is \"$NEXUS_SITE\"):"
    for s in "${NEXUS_SITE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo "BUILD_MODE (default is \"$BUILD_MODE\"):"
    for s in "${BUILD_MODE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "KEY_TYPE (default is \"$KEY_TYPE\"):"
    for s in "${KEY_TYPE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "KMS (default is \"$KMS\"):"
    for s in "${KMS_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "DRM (default is \"$DRM\"):"
    for s in "${DRM_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "TEE_TYPE (default is \"$TEE_TYPE\"):"
    for s in "${TEE_TYPE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "DDR_MODEL (default is \"$DDR_MODEL\"):"
    for s in "${DDR_MODEL_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "SMP (default is \"$SMP\"):"
    for s in "${SMP_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "ACPI (default is \"$ACPI\"):"
    for s in "${ACPI_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "DEBIAN_MODE (default is \"$DEBIAN_MODE\"):(0: without debian, 1: gnome+xfce, 2: gnome, 3: xfce, 4: console)"
    for s in "${DEBIAN_MODE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "FASTBOOT_LOAD (default is \"$FASTBOOT_LOAD\"):(disable, ddr, nvme)"
    for s in "${FASTBOOT_LOAD_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo "NETWORK (default is \"$NETWORK\"):(internal, open)"
    for s in "${NETWORK_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "DOCKER_MODE (default is \"$DOCKER_MODE\"):(none, docker)"
    for s in "${DOCKER_MODE_OPTIONS[@]}" ; do
        echo "    $s"
    done
    echo
    echo "PARALLELISM (the parallel thread count)"
    echo
    echo "MODULE_ONLY (ignore the dependences)"
    echo
    echo "FIRST_MODULE (define the first module, and clear the handled modules)"
    echo
    echo "INPUT (the attached param)"
    echo
    echo "CMD (default is \"${CMD_DEFAULT[@]}\"):"
    local s_maxlen="0"
    for s in "${CMD_OPTIONS[@]}" ; do
        local i="${#s}"
        (( i > s_maxlen )) && s_maxlen="$i"
    done
    for s in "${CMD_OPTIONS[@]}" ; do
        local -n desc="DO_DESC_$s"
        printf "    %- ${s_maxlen}s    %s\n" "$s" "${desc:+($desc)}"
    done
}

PARALLELISM=`grep -c ^processor /proc/cpuinfo 2>/dev/null`
PLATFORM="$PLATFORM_DEFAULT"
FILESYSTEM="$FILESYSTEM_DEFAULT"
CMD=( "${CMD_DEFAULT[@]}" )
FIRST_MODULE="1"
MODULE_ONLY="0"
while getopts "p:f:j:Mnvd:i:k:m:e:h:b:t:T:r:s:a:x:o:l:w:K:DHU:V:G:" opt; do
    case $opt in
    ("v")
        export http_proxy="http://10.128.30.120:8111"
        export https_proxy="http://10.128.30.120:8111"
        export ftp_proxy="http://shproxy.cixtech.com:3128"
        #export no_proxy="localhost,localhost:*,127.*,*.cixcomputing.com,*.cixtech.com,*.cixcomputing.cn,10.128.*"
        export no_proxy="127.0.0.1,repo.cixcomputing.com,codereview.cixtech.com,repo.cixcomputing.cn,10.128.0.0/16,10.134.0.0/16,gitmirror.cixtech.com,artifacts.cixtech.com,ksh-artifacts.cixtech.com"
        echo "config proxy-http_proxy:$http_proxy , no_proxy:$no_proxy"
        ;;
    ("d") BUILD_MODE="$OPTARG" ;;
    ("k") KEY_TYPE="$OPTARG" ;;
    ("m") KMS="$OPTARG" ;;
    ("e") DRM="$OPTARG" ;;
    ("t") TEE_TYPE="$OPTARG" ;;
    ("r") DDR_MODEL="$OPTARG" ;;
    ("s") SMP="$OPTARG" ;;
    ("a") ACPI="$OPTARG" ;;
    ("j") PARALLELISM="$OPTARG" ;;
    ("p") PLATFORM="$OPTARG" ;;
    ("f") FILESYSTEM="$OPTARG" ;;
    ("h") SOC_TYPE="$OPTARG" ;;
    ("b") BOARD="$OPTARG" ;;
    ("i") INPUT="$OPTARG" ;;
    ("w") NETWORK="$OPTARG" ;;
    ("?")
        print_usage >&2
        exit 1
        ;;
    ("M") MODULE_ONLY="1" ;;
    ("n") FIRST_MODULE="0" ;;
    ("x") NEXUS_SITE="$OPTARG" ;;
    ("o") DEBIAN_MODE="$OPTARG" ;;
    ("l") FASTBOOT_LOAD="$OPTARG" ;;
    ("K") DOCKER_MODE="$OPTARG" ;;
    ("U") KMS_PROJECT_ID="$OPTARG" ;;
    ("V") KMS_VERSION="$OPTARG" ;;
    ("G") AUTO_GUID="$OPTARG" ;;
    ("D") DEPENDEE="dependee" ;;
    ("H")
        print_usage
        exit 0
    esac
done
shift $((OPTIND-1))

in_haystack "$PLATFORM" "${PLATFORM_OPTIONS[@]}" ||
    die "invalid PLATFORM: $PLATFORM"
#readonly PLATFORM

if [[ -z "${FILESYSTEM:-}" ]] ; then
    echo "ERROR: Mandatory -f FILESYSTEM not given!" >&2
    echo "" >&2
    print_usage >&2
    exit 1
fi
in_haystack "$NEXUS_SITE" "${NEXUS_SITE_OPTIONS[@]}" ||
    die "invalid NEXUS_SITE: $NEXUS_SITE"

in_haystack "$BUILD_MODE" "${BUILD_MODE_OPTIONS[@]}" ||
    die "invalid BUILD_MODE: $BUILD_MODE"

in_haystack "$FILESYSTEM" "${FILESYSTEM_OPTIONS[@]}" ||
    die "invalid FILESYSTEM: $FILESYSTEM"

in_haystack "$SOC_TYPE" "${SOC_TYPE_OPTIONS[@]}" ||
    die "invalid SOC_TYPE: $SOC_TYPE"

in_haystack "$BOARD" "${BOARD_OPTIONS[@]}" ||
    die "invalid BOARD: $BOARD"

in_haystack "$KEY_TYPE" "${KEY_TYPE_OPTIONS[@]}" ||
    die "invalid KEY_TYPE: $KEY_TYPE"

in_haystack "$KMS" "${KMS_OPTIONS[@]}" ||
    die "invalid KMS: $KMS"

in_haystack "$DRM" "${DRM_OPTIONS[@]}" ||
    die "invalid DRM: $DRM"

in_haystack "$TEE_TYPE" "${TEE_TYPE_OPTIONS[@]}" ||
    die "invalid TEE_TYPE: $TEE_TYPE"

#in_haystack "$DDR_MODEL" "${DDR_MODEL_OPTIONS[@]}" ||
#    die "invalid DDR_MODEL: $DDR_MODEL"

in_haystack "$SMP" "${SMP_OPTIONS[@]}" ||
    die "invalid SMP: $SMP"

in_haystack "$ACPI" "${ACPI_OPTIONS[@]}" ||
    die "invalid ACPI: $ACPI"

in_haystack "$DEBIAN_MODE" "${DEBIAN_MODE_OPTIONS[@]}" ||
    die "invalid DEBIAN_MODE: $DEBIAN_MODE (0: without debian, 1: gnome+xfce, 4: console, 5: openkylin2.0-Release 6:deepin 7:openkylin-alpha)"
    
in_haystack "$FASTBOOT_LOAD" "${FASTBOOT_LOAD_OPTIONS[@]}" ||
    die "invalid FASTBOOT_LOAD: $FASTBOOT_LOAD (disable, ddr, nvme)"

in_haystack "$NETWORK" "${NETWORK_OPTIONS[@]}" ||
    die "invalid NETWORK: $NETWORK (internal, open)"

in_haystack "$DOCKER_MODE" "${DOCKER_MODE_OPTIONS[@]}" ||
    die "invalid DOCKER_MODE: $DOCKER_MODE (none, docker)"

if [[ "$#" -ne 0 ]] ; then
    CMD=( "$@" )
fi
for cmd in "${CMD[@]}" ; do
    in_haystack "$cmd" "${CMD_OPTIONS[@]}" || die "invalid CMD: $cmd"
done
readonly CMD
