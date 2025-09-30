#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

export CIX_VERSION="Beta_2.1.5_release"
export CIX_Deepin_VERSION="Beta_1.0.2_release"
export CIX_Kylin_VERSION="Beta_1.0.2_release"
export debian_cc_version="2025.01.20-1"
BOLD_RED='\033[1;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

readonly DEFAULT_SHELL_OPTS="$(set +o)"
set -E
set -o pipefail
set -u

module_name=$(basename "$0")

function replace_line_offset_lines() {
    local src=$1
    local dst=$2
    local addLine=$3
    local file=$4
    local line=0
    if [[ -e "$file" ]]; then
        set +E
        local res=`grep -n "${src}" "${file}"`
        #echo "res:$res"
        if [[ ${#res} -gt 0 ]]; then
            line=`echo "${res}" | cut -d ":" -f 1`
        fi
        set -E
        #echo "line: $line"
        if [[ $line -gt 0 ]]; then
            line=`expr $line + $addLine`
            sed -i "${line}c${dst}" "${file}"
        fi
    fi
}

function find_and_get_line() {
    local src=$1
    local file=$2
    local line=0
    if [[ -e "$file" ]]; then
        set +E
        local res=`grep -n "${src}" "${file}"`
        if [[ ${#res} -gt 0 ]]; then
            line=`echo "${res}" | cut -d ":" -f 1`
        fi
        set -E
        if [[ $line -gt 0 ]]; then
            sed -n "${line}p" "${file}"
        else
            echo ""
        fi
    fi
}

function replace_or_add_line() {
    local src=$1
    local dst=$2
    local file=$3
    local line=0
    if [[ -e "$file" ]]; then
        set +E
        local res=`grep -n "${src}" "${file}"`
        if [[ ${#res} -gt 0 ]]; then
            line=`echo "${res}" | cut -d ":" -f 1`
        fi
        set -E
        if [[ $line -gt 0 ]]; then
            sed -i "${line}c${dst}" "${file}"
        else
            echo "${dst}" >> "${file}"
        fi
    fi
}

function check_timestamp() {
    local timestamp=$1
    OLD_IFS="$IFS"
    IFS=","
    local resources=($2)
    IFS="$OLD_IFS"

    local len=${#resources[@]}
    for ((i=0;i<$len;i++))
    do
        if [[ -f "${resources[$i]}" ]]; then
            if [[ $(stat -c %Y "${resources[$i]}") -gt $timestamp ]]; then
                echo -e "${GREEN}resource:${resources[$i]} modify time is too new${NORMAL}" >&2
                echo "true"
                return 0
            fi
        fi
        if [[ -d "${resources[$i]}" ]]; then
            for file in "${resources[$i]}"/*; do
                if [[ $(check_timestamp $timestamp "${file}") != "false" ]]; then
                    echo "true"
                    return 0
                fi
            done
        fi
    done

    echo "false"
    return 0
}

function check_compile() {
    if [[ "$FIRST_MODULE" == "1" ]]; then
        echo -e "${GREEN}it is the first module.${NORMAL}" >&2
        echo "true"
        return 0
    fi

    if [[ ! -e "${PATH_OUT}/.compile.csv" ]]; then
        touch "${PATH_OUT}/.compile.csv"
        echo -e "${GREEN}no .compile.csv${NORMAL}" >&2
        echo "true"
        return 0
    fi

    if [[ "\"compile-config\",\"$(cat "${PATH_ROOT}/build-scripts/.env.cix")\"," != "$(find_and_get_line "\"compile-config\"" "${PATH_OUT}/.compile.csv")" ]]; then
        echo -e "${GREEN}config is changed${NORMAL}" >&2
        echo "true"
        return 0
    fi

    local path=$1
    OLD_IFS="$IFS"
    IFS=","
    local resources=($2)
    local targets=($3)
    local record=(`find_and_get_line "\"${path}\"" "${PATH_OUT}/.compile.csv"`)
    IFS="$OLD_IFS"

    local script_time=$(stat -c %Y "${PATH_ROOT}/build-scripts/$module_name")
    if [[ ${#record[@]} -lt 3 ]] || [[ ${script_time} -gt ${record[2]} ]]; then
        if [[ ${#record[@]} -gt 2 ]]; then
            echo -e "${GREEN}script($module_name) is updated:${script_time} -gt ${record[2]}${NORMAL}" >&2
        else
            echo -e "${GREEN}the record is wrong(len < 3)${NORMAL}" >&2
        fi
        echo "true"
        return 0
    fi

    local targetTime=$(date +%s)

    local len=${#targets[@]}
    for ((i=0;i<$len;i++))
    do
        if [[ ! -e "${targets[$i]}" ]]; then
            echo -e "${GREEN}target:${targets[$i]} does not exist${NORMAL}" >&2
            echo "true"
            return 0
        fi
        local t=$(stat -c %Y "${targets[$i]}")
        if [[ $targetTime -gt $t ]]; then
            targetTime=$t
        fi
    done

    local len=${#resources[@]}
    for ((i=0;i<$len;i++))
    do
        if [[ -e "${resources[$i]}" ]]; then
            local t=$(stat -c %Y "${resources[$i]}")
            if [[ $targetTime -lt $t ]]; then
                echo -e "${GREEN}resource:${resources[$i]} modify time is too new${NORMAL}" >&2
                echo "true"
                return 0
            fi
        fi
    done

    # if [[ ! -e "${path}/.git" ]]; then
    #     echo -e "${GREEN}${path} is not a git${NORMAL}" >&2
    #     echo "true"
    #     return 0
    # fi

    pushd "${path}" 1>/dev/null
    local commit_id=$(git rev-parse --short HEAD 2>/dev/null || true)
    popd 1>/dev/null
    if [[ ${#commit_id} -lt 1 ]]; then
        echo -e "${GREEN}${path} is not a git${NORMAL}" >&2
        echo "true"
        return 0
    fi

    if [[ ${#commit_id} -gt 12 ]]; then
        echo -e "${GREEN}${path} is not a git${NORMAL}" >&2
        echo "true"
        return 0
    fi

    if [[ ${#record[@]} -lt 2 ]] || [[ "\"${commit_id}\"" != "${record[1]}" ]]; then
        if [[ ${#record[@]} -gt 1 ]]; then
            echo -e "${GREEN}new commitid:${commit_id} != ${record[1]}${NORMAL}" >&2
        else
            echo -e "${GREEN}the record is wrong(len < 2)${NORMAL}" >&2
        fi
        echo "true"
        return 0
    fi

    pushd "${path}" 1>/dev/null
    local checksum=$(git status -s | md5sum)
    local new_files=($(git status -s | tr ' ' '\n'))
    popd 1>/dev/null

    if [[ ${#record[@]} -lt 4 ]] || [[ "\"${checksum}\"" != "${record[3]}" ]]; then
        if [[ ${#record[@]} -gt 3 ]]; then
            echo -e "${GREEN}md5sum:${checksum} != ${record[3]}${NORMAL}" >&2
        else
            echo -e "${GREEN}the record is wrong(len < 3)${NORMAL}" >&2
        fi
        echo "true"
        return 0
    fi

    if [[ ${#new_files[@]} -gt 0 ]]; then
        local recordTime=0
        if [[ ${#record[@]} -gt 2 ]]; then
            recordTime=${record[2]}
        fi
        for file in ${new_files[@]}; do
            if [[ ${#file} -gt 2 ]] && [[ ${file:0:2} != ".." ]]; then
                local t=0
                if [[ -e "${path}/${file}" ]]; then
                    t=$(stat -c %Y "${path}/${file}")
                fi
                if [[ $recordTime -lt $t ]]; then
                    echo -e "${GREEN}record time is older than the time of ${file}: ${recordTime} -lt ${t}${NORMAL}" >&2
                    echo "true"
                    return 0
                fi
            fi
        done
    fi

    echo "false"
    return 0
}

function record_compile() {
    local path=$1
    pushd "${path}" 1>/dev/null
    local checksum=$(git status -s | md5sum 2>/dev/null || true)
    local commit_id=$(git rev-parse --short HEAD 2>/dev/null || true)
    popd 1>/dev/null
    if [[ ${#commit_id} -lt 1 ]]; then
        commit_id="CIX-$(date +%Y%m%d)"
    fi
    if [[ ${#commit_id} -lt 13 ]]; then
        replace_or_add_line "\"${path}\"" "\"${path}\",\"${commit_id}\",$(date +%s),\"${checksum}\"" "${PATH_OUT}/.compile.csv"
    fi
}

function record_compile_config() {
    if [[ -e "${PATH_ROOT}/build-scripts/.env.cix" ]] && [[ -e "${PATH_OUT}/.compile.csv" ]]; then
        replace_or_add_line "\"compile-config\"" "\"compile-config\",\"$(cat "${PATH_ROOT}/build-scripts/.env.cix")\"," "${PATH_OUT}/.compile.csv"
    fi
}

function millisec2time() {
    local ms=$((${1}%1000))
    local s=$((${1}/1000%60))
    local m=$((${1}/60000%60))
    local h=$((${1}/3600000))
    printf "%02d:%02d:%02d.%03d" $h $m $s $ms
}

function add_built_module() {
    local modules=$(cat "${PATH_ROOT}/.modules")
    if [[ ${#modules} -gt 0 ]]; then
        echo -n " $1" >> "${PATH_ROOT}/.modules"
    else
        echo -n "$1" > "${PATH_ROOT}/.modules"
    fi
}

function handle_dependent_modules() {
    [ -z ${DEPENDENT_MODULES+x} ] && DEPENDENT_MODULES=""

    if [[ ${#DEPENDENT_MODULES} -lt 1 ]]; then
        return
    fi

    echo -e "---handle dependent modules:${GREEN}${DEPENDENT_MODULES}${NORMAL} in ${YELLOW}$module_name${NORMAL}"
    local modules=$(cat "${PATH_ROOT}/.modules")
    for cmd in "${CMD[@]}" ; do
        for arg in $DEPENDENT_MODULES
        do
            local script
            for script in $modules ; do
                if [[ "${script}" == "${arg}" ]]; then
                    break
                fi
            done
            "${PATH_ROOT}/build-scripts/$arg" -D -n -d $BUILD_MODE -p "$PLATFORM" -f "$FILESYSTEM" -h "$SOC_TYPE" -b "$BOARD" -k "$KEY_TYPE" -m "$KMS" -t "$TEE_TYPE" -r "$DDR_MODEL" -s "$SMP" -a "$ACPI" -x "$NEXUS_SITE" -o "$DEBIAN_MODE" -l "$FASTBOOT_LOAD" -e "$DRM" -w "$NETWORK" -K "$DOCKER_MODE" $cmd || exit 1
        done
    done
}

# excute a command with the default shell options (mostly useful with external
# shell functions)
with_default_shell_opts() {
    local -r original_opts="$(set +o)"
    eval "$DEFAULT_SHELL_OPTS"
    "$@"
    local -r i=$?
    eval "$original_opts"
    return $i
}

print_trace() {
    local -a lineno func file
    local len_lineno=0 len_func=0 len_file=0
    local i
    local callinfo
    for ((i=0; ; i++)) ; do
        callinfo="$(caller $((i+1)))" || break

        lineno+=( "${callinfo%% *}" )
        [[ ${#lineno[i]} -lt $len_lineno ]] || len_lineno=${#lineno[i]}
        callinfo="${callinfo#* }"

        func+=( "${callinfo%% *}" )
        [[ ${#func[i]} -lt $len_func ]] || len_func=${#func[i]}
        callinfo="${callinfo#* }"

        file+=( "$callinfo" )
        [[ ${#file[i]} -lt $len_file ]] || len_file=${#file[i]}
    done
    local -r depth="$i"

    local -r fmt_str="%-${len_func}s  %-${len_file}s  %-${len_lineno}s\n"
    printf "$BOLD$fmt_str$NORMAL" "func" "file" "line"
    for ((i=0; i<depth ; i++)) ; do
        printf "$fmt_str" "${func[i]}" "${file[i]}" "${lineno[i]}"
    done
}

handle_error () {
    local -r exit_code=$?
    {
        error_echo "Command terminated with a non-zero code!"
        echo "PLATFORM   = ${PLATFORM:-}"
        echo "FILESYSTEM = ${FILESYSTEM:-}"
        echo "WD         = $PWD"
        echo "EXIT CODE  = $exit_code"
        echo ""
        echo "Build-script call trace:"
        print_trace
    } >&2
    exit 1
}

if [[ -t 1 ]] ; then
    BOLD="\e[1m"
    NORMAL="\e[0m"
    RED="\e[31m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    BLUE="\e[94m"
    CYAN="\e[36m"
else
    BOLD=""
    NORMAL=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
fi
#readonly BOLD NORMAL RED GREEN YELLOW BLUE CYAN

trap handle_error ERR

error_echo() {
    echo -e "$BOLD${RED}ERROR:$NORMAL$RED $*$NORMAL" >&2
}

die() {
    error_echo "$*"
    exit 1
}

in_haystack() {
    local -r needle="$1" ; shift
    local haystack
    for haystack in "$@" ; do
        [[ $needle != $haystack ]] || return 0
    done
    return 1
}

esp_compress() {
    case "${COMPRESS_ESP^^}" in
    ("GZIP") gzip -v ;;
    ("NONE") cat ; return ;;
    (*) die "Unsupported COMPRESS_ESP config value: $COMPRESS_ESP" ;;
    esac
}

readonly DO_DESC_all="alias for \"clean build\""
do_all() {
    cd "$WORKSPACE_DIR"
    do_clean
    cd "$WORKSPACE_DIR"
    do_build
}

function getPkgVer() {
    local pkg_Name="$1"

    CHANGELOG="$PATH_CHANGELOGS/changelog.${pkg_Name}"
    if [[ ! -f "$CHANGELOG" ]]; then
        echo -e $BOLD_RED"ERROR: changelog not found：$CHANGELOG"$RESET >&2
        echo -e $GREEN"If you submit a new package,please add a changelog file in the changelogs directory"$RESET >&2
        exit 1
    fi

    if pkg_Ver=$(grep -m 1 -oP '^\S+\s+\(\K[^)]+(?=\))' "$CHANGELOG"); then
        echo $pkg_Ver
    else
        echo -e $BOLD_RED"ERROR: get Version failed from: $CHANGELOG"$RESET >&2
        echo -e $BOLD_RED"Please check the version format in changelog file"$RESET >&2
        echo -e $GREEN"You can find the rule in: https://confluence.cixtech.com/pages/viewpage.action?pageId=109760824"$RESET >&2
        exit 1
    fi
}

function create_cix_deb() {
    local pkg_Name="$1"

    CHANGELOG="$PATH_CHANGELOGS/changelog.${pkg_Name}"

    # read CHANGELOG pkg_Ver < <(getPkgVer $1)
    pkg_Ver=$(getPkgVer $pkg_Name)

    local build_deb_dir="${PATH_OUT_DEB_PACKAGES}/${pkg_Name}"

    case "$pkg_Name" in
    ("cix-mesa")
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: libc6 (>= 2.34)
Provides: libgl1-mesa-dri, libgl1, libglapi-mesa, libgl-dev
Replaces: libgl1-mesa-dri, libgl1, libglapi-mesa, libgl-dev
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    ("cix-xwayland")
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: libc6 (>= 2.34)
Provides: xwayland
Replaces: xwayland
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    ("cix-gpu-umd")
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: libc6 (>= 2.34)
Provides: libwayland-dev, libwayland-egl1, libgles2, ocl-icd-libopencl1, libgbm1, libegl-dev, libgles1, libegl1, libgles1, libgles-dev, ocl-icd-opencl-dev, libgbm-dev
Replaces: libwayland-dev, libwayland-egl1, libgles2, ocl-icd-libopencl1, libgbm1, libegl-dev, libgles1, libegl1, libgles1, libgles-dev, ocl-icd-opencl-dev, libgbm-dev
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    ("cix-gstreamer")
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: libc6 (>= 2.34), libglib2.0-0, libglib2.0-bin, libx11-6, libgdk-pixbuf-2.0-0, zlib1g, libasound2, libogg0, libopus0, libxext6, libxi6, libxfixes3, libxdamage1, libxml2, libnettle8, libcairo2, libjpeg62-turbo, libpng16-16, libsoup-3.0-0, libva-drm2, libva-glx2, libva-wayland2, libva-x11-2, libva2, libdrm2, libdrm-radeon1, libdrm-nouveau2, libdrm-amdgpu1, libdrm-freedreno1, libdrm-tegra0, libdrm-etnaviv1, libvulkan1, libxcb1, libxkbcommon0, libwayland-client0, libwayland-server0, libwayland-cursor0, libwayland-egl1, libwayland-bin, libnice10, libwebp7, libwebpmux3, libwebpdemux2, libjson-glib-1.0-0, libpango-1.0-0, libpangocairo-1.0-0, libpangoft2-1.0-0, libpangoxft-1.0-0
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    ("cix-npu-onnxruntime")
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: python3-pip
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    (*)
        CONTROL_CONTENT="Package: ${pkg_Name}
Version: ${pkg_Ver}
Architecture: arm64
Maintainer: Cix OS team
Depends: libc6 (>= 2.34)
Section: utils
Priority: optional
Description: $pkg_Name package"
        ;;
    esac

    if [[ -e $build_deb_dir/usr/share/doc/$pkg_Name ]]; then
        if [[ -e $build_deb_dir/usr/share/doc/$pkg_Name/changelog.Debian.gz ]]; then
            rm -rf  $build_deb_dir/usr/share/doc/$pkg_Name/changelog.Debian.gz
        fi
    else
        mkdir -p $build_deb_dir/usr/share/doc/$pkg_Name
    fi

    cp $CHANGELOG $build_deb_dir/usr/share/doc/$pkg_Name/changelog.Debian
    gzip $build_deb_dir/usr/share/doc/$pkg_Name/changelog.Debian

    if [[ -e $PATH_OUT_PRIVATE_DEB_PACKAGES/copyright/$pkg_Name ]]; then
        cp $PATH_OUT_PRIVATE_DEB_PACKAGES/copyright/$pkg_Name/copyright $build_deb_dir/usr/share/doc/$pkg_Name
    fi

    if [[ ! -e "$build_deb_dir/DEBIAN/control" ]]; then
        mkdir -p "$build_deb_dir/DEBIAN"
        echo "${CONTROL_CONTENT}" > "$build_deb_dir/DEBIAN/control"
    else
        sed -i "s/^Version: .*/Version: $pkg_Ver/" "$build_deb_dir/DEBIAN/control"
    fi

    chmod -R 755 "$build_deb_dir"
    chmod -R g-s "$build_deb_dir"
    rm -f ${PATH_DEB}/${pkg_Name}_*.deb
    dpkg-deb -b --root-owner-group "$build_deb_dir" "${PATH_DEB}/${pkg_Name}_${pkg_Ver}_arm64.deb"
}

function cix_deb_package() {
    local packageName="$1"
    local packageFile="$2"
    local path="$3" #"${PATH_OUT}/deb_packages/${packageName}"
    if [[ -e "${path}/DEBIAN" ]]; then
        rm -rf "${path}/DEBIAN"
    fi
    mkdir -p "${path}/DEBIAN"
    echo "packageName: $packageName, path: $path"
    local copyright=$(cat <<- EOF
#!/bin/bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
EOF
)
    local curDate=$(date "+%Y-%m-%d")
    #local curTime=$(date "+%Y-%m-%d %H:%M%S")

    cat > "${path}/DEBIAN/control" <<- EOF
Package: ${packageName}
Version: ${curDate}
Architecture: arm64
Section: install package
Priority: required
Maintainer: Xinjun
Homepage: https://www.cixtech.com/
Description: Cix Deb Installing Package for the third party
EOF

    cat > "${path}/DEBIAN/preinst" <<- EOF
${copyright}

#
# Description: the script will be called before install
# Author: Xinjun
# Date: ${curDate}
# Revision: original v1.0
#

if [[ ! -v PATH ]] || [[ "\$PATH" != *"/usr/share/cix/bin"* ]]; then
    echo "export PATH=/usr/share/cix/bin:\\\$PATH" >> ~/.bashrc
fi
if [[ ! -v LD_LIBRARY_PATH ]] || [[ "\$LD_LIBRARY_PATH" != *"/usr/share/cix/lib"* ]]; then
    echo "export LD_LIBRARY_PATH=/usr/share/cix/lib:\\\$LD_LIBRARY_PATH" >> ~/.bashrc
fi
source ~/.bashrc

EOF
    cix_deb_preinst "${path}/DEBIAN/preinst"

    cat > "${path}/DEBIAN/postinst" <<- EOF
${copyright}

#
# Description: the script will be called after install
# Author: Xinjun
# Date: ${curDate}
# Revision: original v1.0
#

EOF
    cix_deb_postinst "${path}/DEBIAN/postinst"

    cat > "${path}/DEBIAN/prerm" <<- EOF
${copyright}

#
# Description: the script will be called before uninstall
# Author: Xinjun
# Date: ${curDate}
# Revision: original v1.0
#

EOF
    cix_deb_prerm "${path}/DEBIAN/prerm"

    cat > "${path}/DEBIAN/postrm" <<- EOF
${copyright}

#
# Description: the script will be called after uninstall
# Author: Xinjun
# Date: ${curDate}
# Revision: original v1.0
#

EOF
    cix_deb_postrm "${path}/DEBIAN/postrm"

    chmod -R 755 "${path}"
    chmod -R g-s "${path}"

    dpkg -b "${path}" "${PATH_DEB}/${packageFile}"
}

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

copy_dir() {
    local FORCE=""
    if [[ ! -e "$1" ]]; then
        return
    fi
    if [[ $# -gt 2 ]]; then
        FORCE=$3
    fi
    if [[ -d "$1" ]]; then
        $FORCE rsync -arh $1/* $2
    else
        $FORCE rsync -arh $1 $2
    fi
}

function cix_download() { #-s <src> -f <saved path> -d <expend path> -b <backup file> -p <cmd prefix[sudo]> -m <md5>
    local _nexus="$NEXUS_SITE"
    local dl="${HOME}/dl"
    local src=""
    local dest=""
    local backup=""
    local prefix=""
    local md5=""
    local file

    if [[ ! -e "${HOME}/dl" ]]; then
        mkdir "${HOME}/dl"
    fi
    OPTIND=0
    while getopts "s:f:d:b:p:m:" opt; do
        case $opt in
        ("s") src="$OPTARG" ;;
        ("f") dl="$OPTARG" ;;
        ("d") dest="$OPTARG" ;;
        ("b") backup="$OPTARG" ;;
        ("p") prefix="$OPTARG" ;;
        ("m") md5="$OPTARG" ;;
        esac
    done

    local name=$(echo $src | awk -F ':' '{print $2}')
    name=${name/\%2F/\/}
    if [[ -d "$dl" ]]; then
        file="$dl/${name}"
    else
        file="$dl"
    fi
    local path=$(dirname $file)
    if [[ ! -e "$path" ]]; then
        mkdir -p $path
    fi

    #echo "src: $src"
    #echo "dest: $dest"
    #echo "backup: $backup"
    if [[ ${#backup} -gt 0 ]] && [[ -e "${PATH_ROOT}/ext/mirror/${backup}" ]]; then
        if [[ "$dl" != "${HOME}/dl" ]]; then
            cp -f "${PATH_ROOT}/ext/mirror/${backup}" $file
        fi
        if [[ ${#dest} -gt 0 ]]; then
            if [[ ! -e "${dest}" ]]; then
                mkdir -p "${dest}"
            fi
            if [[ "${backup: -4}" == ".tgz" ]]; then
                ${prefix} tar -xzf "${PATH_ROOT}/ext/mirror/${backup}" --numeric-owner -C "${dest}"
            elif [[ "${backup: -4}" == ".deb" ]]; then
                dpkg-deb -R "${PATH_ROOT}/ext/mirror/${backup}" "${dest}"
            fi
        fi
        return
    fi

    if [[ "${NEXUS_SITE}" == "release" ]] || [[ "${NEXUS_SITE}" == "customer" ]]; then
        if [[ -e "${file}" ]]; then
            return
        fi
        echo -e "${RED}Error: resources are absent. maybe doing next can help you.${NORMAL}"
cat <<EOF
    source ./build-scripts/envtool.sh
    updateres
EOF
        exit 1
    fi

    if [[ "$_nexus" != "zj" ]] && [[ "$_nexus" != "wuh" ]] && [[ "$_nexus" != "szv" ]] && [[ "$_nexus" != "ksh" ]] && [[ "$_nexus" != "wux" ]]; then
        _nexus="zj"
    fi
    if [[ "$_nexus" != "" ]]; then
        _nexus="${_nexus}-"
    fi

    local repository=$(echo $src | awk -F ":" '{print $1}')
    if [[ ! -e "${PATH_OUT}/mirror" ]]; then
        mkdir "${PATH_OUT}/mirror"
    fi
    local file_md5=""
    if [[ -e "${file}" ]]; then
        file_md5=$(md5sum "${file}" | awk '{print $1}')
    fi
    EX_NEXUS_USER=${EX_NEXUS_USER-svc.public}
    EX_NEXUS_PASS=${EX_NEXUS_PASS-svc.public}
    local nexus_md5=$(curl -k -s -X GET -u "${EX_NEXUS_USER}:${EX_NEXUS_PASS}" "https://${_nexus}artifacts.cixtech.com/service/rest/v1/search?repository=${repository}&name=${name}" |jq -r '.items[0].assets[0].checksum.md5')

    if [ "$file_md5" != "$nexus_md5" ]; then
        echo "file_md5:${file_md5},nexus_md5:${nexus_md5}"
        rm -f "${file}"
        wget -O "${file}"  --no-check-certificate --user=${EX_NEXUS_USER} --password=${EX_NEXUS_PASS} "https://${_nexus}artifacts.cixtech.com/repository/${repository}/${name}"
        if [[ ${#dest} -gt 0 ]]; then
            if [[ -e "${dest}" ]]; then
                ${prefix} rm -rf "${dest}"
            fi
        fi
    fi
    if [[ ! -e "${file}" ]]; then
        echo -e "${BOLD}${RED}download (${file}) failed. ${NORMAL}"
        exit 1
    fi

    if [[ ${#dest} -gt 0 ]]; then
        if [[ ! -e "${dest}" ]]; then
            mkdir -p "${dest}"
        fi
        if [[ "${file: -4}" == ".tgz" ]]; then
            ${prefix} tar -xzf "${file}" --numeric-owner -C "${dest}"
        elif [[ "${file: -4}" == ".deb" ]]; then
            dpkg-deb -R "${file}" "${dest}"
        fi
        ls "${dest}"
    fi
    if [[ ${#backup} -gt 0 ]]; then
        cp -f "$file" "${PATH_OUT}/mirror/$backup"
    fi
}

# custom text set by the component script
readonly DO_DESC_build
readonly DO_DESC_clean

NEXUS_SITE=${NEXUS_SITE:-zj}

#readonly SCRIPT_DIR="$(realpath --no-symlinks "$(dirname "${BASH_SOURCE[0]}")")"
readonly SCRIPT_DIR=$(cix_realpath "${BASH_SOURCE[0]}")
readonly WORKSPACE_DIR="$(realpath --no-symlinks "$SCRIPT_DIR/..")"

source "$SCRIPT_DIR/parse_params.sh"

export NEXUS_SITE=$NEXUS_SITE
INPUT=${INPUT:-}
export INPUT=${INPUT## }
export PARALLELISM=$PARALLELISM
export BUILD_MODE=$BUILD_MODE
export SOC_TYPE=$SOC_TYPE
export BOARD=$BOARD
export SMP=$SMP
export ACPI=$ACPI
export DEBIAN_MODE=$DEBIAN_MODE
export NETWORK=$NETWORK
export DOCKER_MODE=$DOCKER_MODE
export KMS_PROJECT_ID=${KMS_PROJECT_ID:-sky1_a0_test}
export KMS_VERSION=${KMS_VERSION:-1.0.2}
export AUTO_GUID=${AUTO_GUID:-1}
export SECURE_STORAGE=${SECURE_STORAGE:-none}
CIX_ANDROID_BOOT=${CIX_ANDROID_BOOT:-}
if [[ "$CIX_ANDROID_BOOT" == "nvme" || "$CIX_ANDROID_BOOT" == "ddr" || "$CIX_ANDROID_BOOT" == "usb" ]]; then
  export FASTBOOT_LOAD=$CIX_ANDROID_BOOT
else
  export FASTBOOT_LOAD=$FASTBOOT_LOAD
fi

export PATH_ROOT="$WORKSPACE_DIR"
export CCACHE="0"
# if [ -e "/usr/bin/ccache" ]; then
#   export CCACHE="1"
#   if [ -e "/data/.c/ccache" ]; then
#     ccache -o cache_dir=/data/.c/ccache
#     ccache -o max_size=60G
#   else
#     ccache -o max_size=20G
#   fi
# else
#   export CCACHE="0"
# fi

if [[ "$FIRST_MODULE" == "1" ]]; then
    startTime=$(date +%s%3N)
    #source "$SCRIPT_DIR/check_dep.sh"
    echo -n "$module_name" > "${PATH_ROOT}/.modules"
    echo -n "" > "${PATH_ROOT}/.modules_stastics"
else
    modules=$(cat "${PATH_ROOT}/.modules")
    for script in $modules ; do
        if [[ "${script}" == "${module_name}" ]]; then
            echo -e "---ignore dependence ${GREEN}${module_name}${NORMAL} which has handled."
            exit 0
        fi
    done
    add_built_module "$module_name"
fi

if [[ "$MODULE_ONLY" == "0" ]]; then
    handle_dependent_modules
fi

moduleBeginTime=$(date +%s%3N)

case "$PLATFORM" in
(*)
    export PLAT_PREFIX=""
    ;;
esac

# export STATE_FILE="${PATH_ROOT}/build-scripts/.build_state"
#export ARM_TOOLCHAIN=gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
export ARM_TOOLCHAIN=arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu
if [[ ! -e "${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}" ]]; then
    export ARM_TOOLCHAIN=gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
fi
export ARM_TOOLCHAIN_ELF=gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf
export ARM_TOOLCHAIN_EABI=gcc-arm-none-eabi-10.3-2021.10-x86_64-linux
export ARM_TOOLCHAIN_EXTRA=$ARM_TOOLCHAIN #gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu #${ARM_TOOLCHAIN} for the end user, temporary for 3588

if [[ $CCACHE == "1" ]]; then
export CROSS_COMPILE="${PATH_ROOT}/build-scripts/ccache-gcc/${ARM_TOOLCHAIN}/bin/aarch64-none-linux-gnu-"
export CROSS_COMPILE_ELF="${PATH_ROOT}/build-scripts/ccache-gcc/${ARM_TOOLCHAIN_ELF}/bin/aarch64-none-elf-"
export CROSS_COMPILE_EABI="${PATH_ROOT}/build-scripts/ccache-gcc/${ARM_TOOLCHAIN_EABI}/bin/arm-none-eabi-"
export CROSS_COMPILE_EXTRA="${PATH_ROOT}/build-scripts/ccache-gcc/${ARM_TOOLCHAIN_EXTRA}/bin/aarch64-none-linux-gnu-"
else
export CROSS_COMPILE="${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN}/bin/aarch64-none-linux-gnu-"
export CROSS_COMPILE_ELF="${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN_ELF}/bin/aarch64-none-elf-"
export CROSS_COMPILE_EABI="${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN_EABI}/bin/arm-none-eabi-"
export CROSS_COMPILE_EXTRA="${PATH_ROOT}/tools/gcc/${ARM_TOOLCHAIN_EXTRA}/bin/aarch64-none-linux-gnu-"
fi

case "$FILESYSTEM" in
("debian")
readonly PLATFORM_OUT_DIR="${WORKSPACE_DIR}/output/${PLATFORM}_${BOARD}"
export PATH_OUT="${PLATFORM_OUT_DIR}"
export PATH_SYSROOT="${PATH_OUT}/sysroot"
export PATH_OUT_DEB_PACKAGES="${PATH_OUT}/debs_tmp"
export PRIVATE_DEB_PACKAGES=("cix-dpu-ddk" "cix-npu-umd" "cix-isp-umd" "cix-gpu-umd" "cix-audio-dsp" "cix-hdcp2" "cix-noe-umd")

#export PATH_DEBIAN="${PATH_ROOT}/debian"
#export PATH_DEBIAN="${PATH_OUT}/debian_desktop"
export PATH_DEBIAN="${PATH_OUT}/debian"
export PATH_DEB="${PATH_OUT}/debs"
export PATH_DEBIAN_COMPILE="${PATH_OUT}/debian_compile"
export PATH_DEBIAN_COMPILE_mutter="${PATH_OUT}/debian_compile_mutter"
export PATH_DEBIAN_COMPILE_debian_cc="${PATH_OUT}/debian_cc"
export PATH_CHANGELOGS="${PATH_ROOT}/build-scripts/changelogs"
export PATH_SOURCE_DEB="${PATH_ROOT}/debian12/os/source_deb"
export PRE_COMPILE_DEB="${PATH_ROOT}/debian12/os/debs"

export PATH_LINUX="${PATH_ROOT}/${PLAT_PREFIX}linux"
    ;;
("android")
readonly PLATFORM_OUT_DIR=$WORKSPACE_DIR
export PATH_OUT="${PLATFORM_OUT_DIR}/out/target/product/sky1_$BOARD/"
    ;;
("none")
readonly PLATFORM_OUT_DIR="${WORKSPACE_DIR}/output/${PLATFORM}_${BOARD}"
export PATH_OUT="${PLATFORM_OUT_DIR}"
    ;;
esac

if [[ ! -e "${PATH_OUT}" ]]; then
    mkdir -p "${PATH_OUT}"
fi

if [[ ! -e "${PATH_OUT}/parallel_logs" ]]; then
    mkdir -p "${PATH_OUT}/parallel_logs"
fi

if [[ ! -e "${PATH_OUT}/images" ]]; then
    mkdir -p "${PATH_OUT}/images"
fi

SYSROOT_VERSION="20250325-1"
REMOTE_SYSROOT_MD5="2e0cf0bf96b9287eca57e27e4a3cadbb"
SYSROOT_MD5=""
case "$FILESYSTEM" in
("debian")
    if [[ ! -e "${PATH_OUT_DEB_PACKAGES}" ]]; then
        mkdir -p "${PATH_OUT_DEB_PACKAGES}"
    fi
    if [[ ! -e "${PATH_DEB}" ]]; then
        mkdir -p "${PATH_DEB}"
    fi

    if [[ -e "${PATH_ROOT}/ext/mirror/cix_sysroot.tgz" ]]; then
        if [[ ! -e "${PATH_SYSROOT}" ]]; then
            mkdir -p "${PATH_SYSROOT}"
        fi
        if [[ ! -e "${PATH_SYSROOT}/usr/share/cix" ]]; then
            tar -xzf "${PATH_ROOT}/ext/mirror/cix_sysroot.tgz" -C "${PATH_SYSROOT}"
            if [[ -e "${PATH_SYSROOT}/cix_sysroot" ]]; then
                cp -drfp "${PATH_SYSROOT}/cix_sysroot"/* "${PATH_SYSROOT}/"
                rm -rf "${PATH_SYSROOT}/cix_sysroot"
            fi
        fi
    else
        if [[ -e "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz" ]]; then
            if [[ -e "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz.md5" ]]; then
                SYSROOT_MD5=$(cat "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz.md5")
            else
                SYSROOT_MD5=$(md5sum "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz" | awk '{print $1}')
            fi
        fi
        if [[ "${REMOTE_SYSROOT_MD5}" != "${SYSROOT_MD5}" ]]; then
            cix_download -s "debian12_dev_env:sysroot%2Fcix_sysroot-${SYSROOT_VERSION}.tgz" -d "${HOME}/dl/sysroot-${SYSROOT_VERSION}" -b "cix_sysroot.tgz" -m "${REMOTE_SYSROOT_MD5}"
        fi
        if [[ ! -e "${PATH_SYSROOT}" ]]; then
            mkdir -p "${PATH_SYSROOT}"
        fi
        if [[ ! -e "${PATH_SYSROOT}/usr/share/cix" ]]; then
            if [[ -e "${HOME}/dl/sysroot-${SYSROOT_VERSION}/cix_sysroot" ]]; then
                cp -drfp "${HOME}/dl/sysroot-${SYSROOT_VERSION}/cix_sysroot"/* "${PATH_SYSROOT}/"
            fi
        fi
        if [[ ! -e "${PATH_OUT}/mirror/cix_sysroot.tgz" ]]; then
            if [[ ! -e "${PATH_OUT}/mirror" ]]; then
                mkdir "${PATH_OUT}/mirror"
            fi
            if [[ -e "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz" ]]; then
                cp -f "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz" "${PATH_OUT}/mirror/cix_sysroot.tgz"
            fi
        fi
        if [[ ! -e "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz.md5" ]]; then
            echo "${REMOTE_SYSROOT_MD5}" > "${HOME}/dl/sysroot/cix_sysroot-${SYSROOT_VERSION}.tgz.md5"
        fi
    fi
    ;;
esac

export PATH_CIX_BINARY="${PATH_ROOT}/tools/cix_binary"

case "$FILESYSTEM" in
("debian")
    export PATH_CIX_PROPRIETARY="${PATH_ROOT}/component/cix_proprietary"
    export PATH_OUT_PRIVATE_DEB_PACKAGES="${PATH_CIX_PROPRIETARY}/cix_proprietary-debs"
    export PATH_EXPORT_SECURITY="${PATH_ROOT}/security"
    export PATH_EXPORT_FIRMWARE="${PATH_ROOT}/component/cix_firmware/${BUILD_MODE}"
    export PATH_EXPORT_COMMON_FIRMWARE="${PATH_ROOT}/component/cix_firmware/common"
    export PATH_EXPORT_FIRMWARE_LIB="${PATH_EXPORT_SECURITY}/library"
    export PATH_EXPORT_ROOTFS="${PATH_SYSROOT}"

    if [[ "$FIRST_MODULE" == "1" ]]; then
        if [[ -e "${PATH_CIX_PROPRIETARY}/cix_proprietary-debs" ]]; then
            for file in "${PATH_CIX_PROPRIETARY}/cix_proprietary-debs"/*; do
                if [[ $(basename "${file}") != "pool" && $(basename "${file}") != "cix-grubcfg-1.0" ]]; then
                    echo "copy ${file} to sysroot"
                    copy_dir ${file} ${PATH_SYSROOT}
                fi
            done
        fi
    fi
    ;;
("android")
    export PATH_CIX_PROPRIETARY="${PATH_ROOT}/vendor/cix_proprietary"
    export PATH_EXPORT_SECURITY="${PATH_ROOT}/vendor/cix_private/security"
    export PATH_EXPORT_FIRMWARE="${PATH_ROOT}/vendor/cix_firmware/${BUILD_MODE}"
    export PATH_EXPORT_COMMON_FIRMWARE="${PATH_ROOT}/vendor/cix_firmware/common"
    export PATH_EXPORT_FIRMWARE_LIB="${PATH_EXPORT_SECURITY}/library"
    export PATH_EXPORT_ROOTFS="${PATH_CIX_PROPRIETARY}/android_rootfs"
    ;;
("none")
    export PATH_EXPORT_FIRMWARE="${PATH_ROOT}/component/cix_firmware"
    ;;
esac

case "$FILESYSTEM" in
("debian")
    export PATH_EXPORT_INCLUDE="${PATH_EXPORT_ROOTFS}/usr/share/cix/include"
    export PATH_EXPORT_LIB="${PATH_EXPORT_ROOTFS}/usr/share/cix/lib"
    export PATH_EXPORT_BIN="${PATH_EXPORT_ROOTFS}/usr/share/cix/bin"
    export PATH_OUT_ROOTFS="${PATH_OUT}/rootfs"

    case "$PLATFORM" in
    ("cix")
        if [[ ! -e "${PATH_EXPORT_INCLUDE}" ]]; then
            mkdir -p "${PATH_EXPORT_INCLUDE}"
        fi
        if [[ ! -e "${PATH_EXPORT_LIB}" ]]; then
            mkdir -p "${PATH_EXPORT_LIB}"
        fi
        if [[ ! -e "${PATH_EXPORT_BIN}" ]]; then
            mkdir -p "${PATH_EXPORT_BIN}"
        fi
        ;;
    esac

    linux_version="6.1"
    if [[ -e "${PATH_LINUX}" ]]; then
        if [[ ! -e "${PATH_LINUX}/include/config/kernel.release" ]]; then
            case "$PLATFORM" in
            ("cix")
                config_file="defconfig cix.config"
                ;;
            (*)
                config_file=defconfig
                ;;
            esac
            cd "${PATH_LINUX}"
            make ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}" LOCALVERSION="-generic" ${config_file} prepare || exit 1
            cd -
        fi
        linux_version=`cat "${PATH_LINUX}/include/config/kernel.release"`
    fi

esac

if [[ ! -v PATH ]] || [[ "${PATH}" != *"${PATH_ROOT}/build-scripts/bin"* ]]; then
    export PATH=${PATH_ROOT}/build-scripts/bin:${PATH}
fi

if [[ ! -v PATH ]] || [[ "${PATH}" != *"${PATH_ROOT}/tools/llvm/bin"* ]]; then
    export PATH=${PATH_ROOT}/tools/llvm/bin:${PATH}
fi

if [[ ! -v PATH ]] || [[ "${PATH}" != *"${PATH_ROOT}/tools/gcc/gcc/bin"* ]]; then
    export PATH=${PATH_ROOT}/tools/gcc/gcc/bin:${PATH}
fi

CIX_ANDROID_BUILD_MODE=${CIX_ANDROID_BUILD_MODE:-}
if [ $CIX_ANDROID_BUILD_MODE ]; then
    export BUILD_MODE=$CIX_ANDROID_BUILD_MODE
fi

echo "${PATH_ROOT}/build-scripts/$module_name -d $BUILD_MODE -p $PLATFORM -f $FILESYSTEM -h $SOC_TYPE -b $BOARD -k $KEY_TYPE -m $KMS -t $TEE_TYPE -r $DDR_MODEL -s $SMP -a $ACPI -x $NEXUS_SITE -o $DEBIAN_MODE -l $FASTBOOT_LOAD -e $DRM -w $NETWORK -K $DOCKER_MODE ${CMD[@]}"

echo "******************ENV VALUE***********************"
echo "CIX_VERSION:                   "$CIX_VERSION
echo "DEPENDEE:                      "$DEPENDEE
echo "PATH_ROOT:                     "$PATH_ROOT
echo "PATH_OUT:                      "$PATH_OUT
case "$FILESYSTEM" in
("debian")
    echo "PATH_LINUX:                    "$PATH_LINUX
    echo "PATH_DEBIAN:                   "$PATH_DEBIAN
    echo "PATH_DEB:                      "$PATH_DEB
    echo "PATH_OUT_ROOTFS:               "$PATH_OUT_ROOTFS
    #echo "PATH_EXPORT_INCLUDE:           "$PATH_EXPORT_INCLUDE
    #echo "PATH_EXPORT_LIB:               "$PATH_EXPORT_LIB
    #echo "PATH_EXPORT_BIN:               "$PATH_EXPORT_BIN
    echo "PATH_SYSROOT:                  "$PATH_SYSROOT
    ;;
esac
echo "PATH_CIX_BINARY:               "$PATH_CIX_BINARY
echo "PATH_EXPORT_COMMON_FIRMWARE:   "$PATH_EXPORT_COMMON_FIRMWARE
echo "PATH_EXPORT_FIRMWARE:          "$PATH_EXPORT_FIRMWARE
echo "PATH_EXPORT_FIRMWARE_LIB:      "$PATH_EXPORT_FIRMWARE_LIB
if [[ "${FILESYSTEM}" == "debian" ]]; then
    echo "PATH_EXPORT_ROOTFS:            "$PATH_EXPORT_ROOTFS
fi
echo "CROSS_COMPILE_ELF:             "$CROSS_COMPILE_ELF
echo "CROSS_COMPILE:                 "$CROSS_COMPILE
echo "CROSS_COMPILE_EABI:            "$CROSS_COMPILE_EABI
echo "PARALLELISM:                   "$PARALLELISM
echo "BUILD_MODE:                    "$BUILD_MODE
echo "SOC_TYPE:                      "$SOC_TYPE
echo "BOARD:                         "$BOARD
echo "NEXUS_SITE:                    "$NEXUS_SITE
echo "DEBIAN_MODE:                   "$DEBIAN_MODE "(0: without debian, 1: gnome+xfce, 4: console, 5: openkylin2.0-Release, 6: deepin, 7:openkylin-alpha, 8:kylin-v10)"
echo "FASTBOOT_LOAD:                 "$FASTBOOT_LOAD
echo "NETWORK:                       "$NETWORK
echo "DOCKER_MODE:                   "$DOCKER_MODE
echo "INPUT:                         "${INPUT:-}
echo "**************************************************"

for cmd in "${CMD[@]}" ; do
    cd "$WORKSPACE_DIR"
    do_$cmd
done

moduleEndTime=$(date +%s%3N)
moduleElapsedTime=$(millisec2time $(($moduleEndTime - $moduleBeginTime)))
echo -n "${module_name}(${moduleElapsedTime}) " >> "${PATH_ROOT}/.modules_stastics"
#sed -i "s/${module_name}/${module_name}(${moduleElapsedTime})/g" "${PATH_ROOT}/.modules"

if [[ "$FIRST_MODULE" == "1" ]]; then
    echo -e "${CYAN}handled modules:${YELLOW}"
    cat "${PATH_ROOT}/.modules" | sed "s/ /\n/g"
    echo -e "${NORMAL}"
    stopTime=$(date +%s%3N)
    echo "total elapsed time: $(millisec2time $(($stopTime - $startTime)))"
    record_compile_config
fi
