#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#

readonly BOLD="\e[1m"
readonly NORMAL="\e[0m"
readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly BLUE="\e[94m"
readonly CYAN="\e[36m"

function cix_realpath {
    [[ $1 =~ ^/  ]] && a=$1 || a=`pwd`/$1
    while [ -h $a ]
    do
        b=`ls -ld $a|awk '{print $NF}'`
        c=`ls -ld $a|awk '{print $(NF-2)}'`
        [[ $b =~ ^/ ]] && a=$b  || a=`dirname $c`/$b
    done
    echo $(cd `dirname $a`; pwd)
}

readonly PATH_ROOT="$(realpath --no-symlinks $(cix_realpath "${BASH_SOURCE[0]}"))"

debug_help() {
    echo -e "${BOLD}Usage:"
    echo -e "    $0 ${CYAN} [CMD]$NORMAL"
    echo

cat <<EOF
    --kasan:                Enable kasan
    --mte:                  Enable MTE
    --memleak:              Enable memleak
    --deadlock:             Enable deadlock

    --all:                  Enable all debug switches

    --none:                 Disable all debug switches

EOF
}

debug_init() {
    cat > "${FILE_CONFIG}" <<- EOF
# Cix specific options
#
# overlay configs

EOF
}

debug_kasan() {
    cat >> "${FILE_CONFIG}" <<- EOF
# slub configs
CONFIG_SLUB=y
CONFIG_SLUB_DEBUG=y
CONFIG_SLUB_CPU_PARTIAL=y
CONFIG_SLUB_DEBUG_ON=y

#sysfs configs
CONFIG_SYSFS=y

CONFIG_CC_HAS_WORKING_NOSANITIZE_ADDRESS=y

# kasan configs
CONFIG_KASAN_SHADOW_OFFSET=0xdffffc0000000000

CONFIG_HAVE_ARCH_KASAN=y
CONFIG_HAVE_ARCH_KASAN_VMALLOC=y
CONFIG_CC_HAS_KASAN_GENERIC=y
CONFIG_CC_HAS_WORKING_NOSANITIZE_ADDRESS=y
CONFIG_KASAN=y
CONFIG_KASAN_GENERIC=y
# CONFIG_KASAN_OUTLINE is not set
CONFIG_KASAN_INLINE=y
CONFIG_KASAN_STACK=1
CONFIG_KASAN_VMALLOC=y
CONFIG_KASAN_MODULE_TEST=m

EOF
}

debug_mte() {
    cat >> "${FILE_CONFIG}" <<- EOF
CONFIG_KASAN_HW_TAGS=y

#mte configs
CONFIG_ARM64_MTE=y
EOF

    # enable MTE in security firmware
    PATH_FIRMWARE="$(realpath --no-symlinks "${PATH_ROOT}/../security/firmware")"
    if [ "$PLATFORM" = "cix" ] && [ "$FILESYSTEM" = "android" ]; then
   	 PATH_FIRMWARE="$(realpath --no-symlinks "${PATH_ROOT}/../vendor/cix_private/security/firmware")"
    fi
    FIRMWARE_CONFIG="${PATH_FIRMWARE}/config/config.mk"

    if [ -f "$FIRMWARE_CONFIG" ]; then

        # build security firmware
        bash ${PATH_ROOT}/build-firmware.sh
    else
        echo "WARNING: security firmware does not exist. Please download the firmware source code to $PATH_FIRMWARE."
    fi
}

debug_memleak() {
    cat >> "${FILE_CONFIG}" <<- EOF
#memleak
CONFIG_DEBUG_KMEMLEAK=y
CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE=20000
CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF=n
#CONFIG_SAMPLES=y
#CONFIG_DEBUG_KMEMLEAK_TEST=m

EOF
}

debug_deadlock() {
    cat >> "${FILE_CONFIG}" <<- EOF
 # deadlock detection
CONFIG_LOCK_STAT=y
CONFIG_PROVE_LOCKING=y
CONFIG_DEBUG_LOCKDEP=y

EOF
}

debug_all() {
    debug_init
    debug_kasan
    debug_mte
    debug_memleak
    debug_deadlock
}

if [[ $# -lt 1 ]]; then
    debug_help
    exit 0
fi

PATH_KERNEL="$(realpath --no-symlinks "${PATH_ROOT}/../linux")"
if [ $ANDROID_JAVA_TOOLCHAIN ]; then
PATH_KERNEL="$(realpath --no-symlinks "${PATH_ROOT}/../vendor/cix_opensource/kernel")"
fi
FILE_CONFIG="${PATH_KERNEL}/arch/arm64/configs/cix_debug.config"
#echo "FILE_CONFIG: ${FILE_CONFIG}"

debug_init

while [ $# -gt 0 ]; do
    if [[ "$1" == "-k" ]]; then
        shift
        PATH_KERNEL="$(realpath --no-symlinks "${PATH_ROOT}/../$1")"
        FILE_CONFIG="${PATH_KERNEL}/arch/arm64/configs/cix_debug.config"
        #echo "FILE_CONFIG: ${FILE_CONFIG}"
    # elif [[ "$1" == "--kasan" ]]; then
    #     debug_kasan
    # elif [[ "$1" == "--mte" ]]; then
    #     debug_mte
    # elif [[ "$1" == "--memleak" ]]; then
    #     debug_memleak
    elif [[ "$1" == "--all" ]]; then
        debug_all
        break
    elif [[ "$1" == "--none" ]]; then
        debug_init
        break
    elif [[ "$1" == "--"* ]]; then
        debug_${1:2}
    fi
    shift
done

cat "${FILE_CONFIG}"
