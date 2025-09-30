#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

PRIVATE_WORKSPACE=${PWD}

trap '
if [[ -e "/mnt/boot-debian" ]]; then
    sudo umount "/mnt/boot-debian" || true;
fi
' EXIT

isUEFI="1"

function replace_line_if_exist() {
    local src=$1
    local dst=$2
    local file=$3

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
            sed -i "${line}c${dst}" "${file}"
        fi
    fi
}

function copy_if_exist() {
    if [[ -e "$1" ]]; then
        cp -rf "$1" "$2"
    fi
}

function grub_header() {
    echo "set debug="loader,mm"
set term="vt100"
set default="${1}"
set timeout="${2}"
" > "${SCRIPT_DIR}/grub-post-silicon.cfg"
}

function grub_entry() {
    local title="Cix Sky1"
    local acpi="Device Tree"
    local dt=""
    local linux="    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
"
    local initrd=""
    OPTIND=0
    while getopts "t:d:a:r:ni" opt; do
        case $opt in
            ("t")
                #title=$(echo ${OPTARG} | tr a-z A-Z)
                title=${OPTARG}
            ;; #title
            ("d")
                dt="    devicetree /sky1-${OPTARG}.dtb
"
            ;; #device tree
            ("a")
                if [[ "${OPTARG}" == "force" ]]; then
                    acpi="ACPI"
                    linux=$linux"        cma=640M \\
"
                fi
                linux=$linux"        acpi=${OPTARG} \\
"
            ;; #acpi
            ("r") linux=$linux"        root=/dev/${OPTARG} rootwait rw \\
"
            ;; #root
            ("n") linux=$linux"        nosmp \\
"
            ;; #nosmp
            ("i") initrd="    initrd /rootfs.cpio.gz
"
            ;; #initrd
        esac
    done
    linux=$linux"        debug
"
    if [[ "${acpi}" == "ACPI" ]]; then
        dt=""
    fi
    local entry="menuentry '${title} (${acpi})' {
"
    echo "${entry}${dt}${linux}${initrd}}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"
}

readonly DO_DESC_mkgrub="make the grub.cfg for the boards of cix"
do_mkgrub() {
    grub_header 0 2 #<default> <timeout>
    grub_entry -t "0 Cix Sky1 on EVB" -d "evb" -a "off" -r "nvme0n1p2"
    grub_entry -t "1 Cix Sky1 on EVB" -d "evb" -a "force" -r "nvme0n1p2"
    grub_entry -t "2 Cix Sky1 on CRB" -d "crb" -a "off" -r "nvme0n1p2"
    grub_entry -t "3 Cix Sky1 on CRB" -d "crb" -a "force" -r "nvme0n1p2"
    grub_entry -t "4 Cix Sky1 on CLOUDBOOK" -d "cloudbook" -a "off" -r "nvme0n1p2"
    grub_entry -t "5 Cix Sky1 on CLOUDBOOK" -d "cloudbook" -a "force" -r "nvme0n1p2"

    echo "menuentry '6 Cix Sky1 EVB on EMU/FPGA (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        acpi=off \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        nosmp
    initrd /rootfs.cpio.gz
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

    echo "menuentry '7 Cix Sky1 on minisys EVB (Device Tree)' {
    devicetree /sky1-evb-minisys.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        acpi=off \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp
    initrd /rootfs.cpio.gz
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

    grub_entry -t "8 Cix Sky1 CPIO on EVB" -d "evb" -a "off" -i #buildroot
    grub_entry -t "9 Cix Sky1 USB on EVB" -d "evb" -a "off" -r "sda2" #-n #usb
    grub_entry -t "10 Cix Sky1 CPIO on EVB" -d "evb" -a "force" -i #buildroot
    grub_entry -t "11 Cix Sky1 USB on EVB" -d "evb" -a "force" -r "sda2" #-n #usb

echo "menuentry '12 Cix Sky1 on usb smp EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/sda2 rootwait rw
   }
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '13 Cix Sky1 on nvme smp EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
   }
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '14 Cix Sky1 HDA ALC256 NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-hda-alc256.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '15 Cix Sky1 HDA ALC256 USB on EVB (Device Tree)' {
    devicetree /sky1-evb-hda-alc256.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/sda2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '16 Cix Sky1 NFS(10.128.0.10) on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=10.128.0.10:/sw_bringup/nfs_os/debian,proto=tcp,nfsvers=3 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '17 Cix Sky1 NFS(10.128.0.10) smp on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=10.128.0.10:/sw_bringup/nfs_os/debian,proto=tcp,nfsvers=3 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '18 Cix Sky1 NFS(172.16.64.11) on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        nosmp \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=172.16.64.11:/data/debian,proto=tcp,nfsvers=4 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '19 Cix Sky1 NFS(172.16.64.11) smp on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nfs rw nfsroot=172.16.64.11:/data/debian,proto=tcp,nfsvers=4 rootwait ip=dhcp
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"
    grub_entry -t "20 Cix Sky1 USB on CRB" -d "crb" -a "off" -r "sda2"
    grub_entry -t "21 Cix Sky1 USB on CLOUDBOOK" -d "cloudbook" -a "off" -r "sda2"

echo "menuentry '22 Cix Sky1 LT7911UXC AUDIO NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-lt7911uxc-audio.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '23 Cix Sky1 LT7911UXC AUDIO USB on EVB (Device Tree)' {
    devicetree /sky1-evb-lt7911uxc-audio.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/sda2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '24 Cix Sky1 NPU ReserveMEM nvme smp on EVB (Device Tree)' {
    devicetree /sky1-evb-npu-resmem.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '25 Cix Sky1 isp on nvme smp EVB (Device Tree)' {
    devicetree /sky1-evb-isp.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '26 Cix Sky1 performance on EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw \\
        loglevel=6 \\
        systemd.mask=NetworkManager-wait-online.service
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '27 Cix Sky1 on nvme smp docker EVB (Device Tree)' {
    devicetree /sky1-evb.dtb
    linux /Image \
        console=ttyAMA2,115200 \
        efi=noruntime \
        earlycon=pl011,0x040d0000 \
        arm-smmu-v3.disable_bypass=0 \
        acpi=off \
        cpufreq.off=1 \
        cpuidle.off=1 \
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '28 Cix Sky1 on Orion O6 (Device Tree)' {
    devicetree /sky1-orion-o6.dtb
    linux /Image \\
        loglevel=0 \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '29 Cix Sky1 on Orion O6 40 pin (Device Tree)' {
    devicetree /sky1-orion-o6-40pin.dtb
    linux /Image \\
        loglevel=0 \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"

echo "menuentry '30 Cix Sky1 SOF ALC5682-ALC1019 AUDIO NVME on EVB (Device Tree)' {
    devicetree /sky1-evb-sof-alc5682-alc1019.dtb
    linux /Image \\
        console=ttyAMA2,115200 \\
        efi=noruntime \\
        earlycon=pl011,0x040d0000 \\
        arm-smmu-v3.disable_bypass=0 \\
        acpi=off \\
        root=/dev/nvme0n1p2 rootwait rw
}
" >> "${SCRIPT_DIR}/grub-post-silicon.cfg"
}

readonly DO_DESC_build="package all modules into a total image"
do_build() {
    local gpt_btp="${PATH_OUT}/images/partition.bpt"
    local swap_size=${SWAP_SIZE:-0}
    cp -f "${SCRIPT_DIR}/debian/fb/partition.bpt" "${gpt_btp}"
    if [[ ${swap_size} -gt 0 ]]; then
        sed -i "15a\ \ \ \ \ \ \ \ {" "${gpt_btp}"
        sed -i "16a\ \ \ \ \ \ \ \ \ \ \ \ \"label\": \"swap\"," "${gpt_btp}"
        sed -i "17a\ \ \ \ \ \ \ \ \ \ \ \ \"size\": \"${swap_size} MiB\"," "${gpt_btp}"
        sed -i "18a\ \ \ \ \ \ \ \ \ \ \ \ \"guid\": \"auto\"," "${gpt_btp}"
        sed -i "19a\ \ \ \ \ \ \ \ \ \ \ \ \"type_guid\": \"0657FD6D-A4AB-43C4-84E5-0933C84B4F4F\"," "${gpt_btp}"
        sed -i "20a\ \ \ \ \ \ \ \ \ \ \ \ \"name\": \"\"" "${gpt_btp}"
        sed -i "21a\ \ \ \ \ \ \ \ }," "${gpt_btp}"
    fi
    # if [[ -e "${SCRIPT_DIR}/debian/fb/partition-${BOARD}.bpt" ]]; then
    #     cp -f "${SCRIPT_DIR}/debian/fb/partition-${BOARD}.bpt" "${gpt_btp}"
    #     swap_size=$(expr $(sed -n '25p' ${gpt_btp} | awk -F '"' '{print $4}' | awk '{print $1}'))
    # else
    #     cp -f "${SCRIPT_DIR}/debian/fb/partition.bpt" "${gpt_btp}"
    # fi

    local boot_start=$(expr $(sed -n '6p' ${gpt_btp} | awk '{print $2}') / 1024 / 1024)
    local boot_size=$(expr $(sed -n '11p' ${gpt_btp} | awk -F '"' '{print $4}' | awk '{print $1}'))

    #debian rootfs
    local rootfs_ext4="${PATH_OUT}/images/rootfs.ext4"
    local root_size=10
    if [ -e "${rootfs_ext4}" ];then
        root_size=`du -s -b ${rootfs_ext4} | awk '{print $1}'`
        root_size=`expr $root_size / 1024 / 1024 + 10`
    fi
    local total_size=`expr $root_size + $swap_size + $boot_size + $boot_start + 1`
    local swap_start=`expr $boot_size + $boot_start`
    local root_start=`expr $swap_size + $swap_start`

    local boot_end=`expr $swap_start`
    local swap_end=`expr $root_start`
    local root_end=`expr $total_size`

    echo "total size: ${total_size}M"
    echo "boot: ${boot_start}, ${boot_end}M"
    echo "swap: ${swap_start}, ${swap_end}M"
    echo "rootfs: ${root_start}, ${root_end}M"

    replace_line_if_exist "\"disk_size\":" "\ \ \ \ \ \ \ \ \"disk_size\": \"${total_size} MiB\"," "${gpt_btp}"
    if [[ "${AUTO_GUID}" != "0" ]]; then
        replace_line_if_exist "acfba1d2-b17b-40c1-b3a9-e5135c49efa0" "\ \ \ \ \ \ \ \ \ \ \ \ \"guid\": \"auto\"," "${gpt_btp}"
    fi
    sudo "${SCRIPT_DIR}/debian/fb/bpttool" make_table --input "${gpt_btp}" --output_gpt "${PATH_OUT}/images/partition-table.img" --output_json "${PATH_OUT}/partition-table.json"
    sudo "${SCRIPT_DIR}/debian/fb/bpttool" make_table --disk_vector_size 4096 --input "${gpt_btp}" --output_gpt "${PATH_OUT}/images/partition-table-4096.img" --output_json "${PATH_OUT}/partition-table-4096.json"
    sudo chown ${USER}:${USER} "${PATH_OUT}/images/partition-table.img"
    sudo chown ${USER}:${USER} "${PATH_OUT}/images/partition-table-4096.img"

    boot_size=$(expr $boot_size \* 1024 \* 1024)
    echo "boot_start: ${boot_start}Mib, boot_size: ${boot_size} bytes"

    case "$PLATFORM" in
    ("cix")
        local is_post_silicon="false"
        case "$BOARD" in
        ("emu" | "fpga" | "qemu")
            cp "${SCRIPT_DIR}/grub-pre-silicon.cfg" "${SCRIPT_DIR}/grub.cfg"
            if [[ "$ACPI" == "1" ]]; then
                sed -i 's/acpi=off/acpi=force/g' "${SCRIPT_DIR}/grub.cfg"
                sed -i 's/console=ttyAMA2/console=ttyAMA0/g' "${SCRIPT_DIR}/grub.cfg"
                sed -i '/devicetree/d' "${SCRIPT_DIR}/grub.cfg"
            fi
            case "$BOARD" in
            ("emu")
                if [[ "$ACPI" == "1" ]]; then
                    if [[ "$SMP" == "1" ]]; then
                        sed -i '3cset default="12"' "${SCRIPT_DIR}/grub.cfg"
                    else
                        sed -i '3cset default="11"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                else
                    if [[ "$SMP" == "1" ]]; then
                        sed -i '3cset default="8"' "${SCRIPT_DIR}/grub.cfg"
                    else
                        sed -i '3cset default="1"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi
                ;;
            ("fpga")
                if [[ "$ACPI" == "1" ]]; then
                    sed -i '3cset default="0"' "${SCRIPT_DIR}/grub.cfg"
                else
                    sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                fi
                ;;
            ("qemu")
                sed -i '3cset default="4"' "${SCRIPT_DIR}/grub.cfg"
                sed -i '4cset timeout="5"' "${SCRIPT_DIR}/grub.cfg"
                ;;
            esac

            if  [[ "$FASTBOOT_LOAD" == "nvme" ]]; then
                sed -i '3cset default="13"' "${SCRIPT_DIR}/grub.cfg"
            elif [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
            elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
            fi
            ;;
        (*)
            cp "${SCRIPT_DIR}/grub-post-silicon.cfg" "${SCRIPT_DIR}/grub.cfg"
            sed -i s/linux_version/${linux_version}/g ${SCRIPT_DIR}/grub.cfg
            if [[ "${swap_size}" != "0" ]]; then
                local swap_device_guid=$("${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" | grep "PARTITION1, guid:" | awk -F ":" '{print $2}')
                local root_device_guid=$("${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" | grep "PARTITION2, guid:" | awk -F ":" '{print $2}')
                sed -i "s:root=/dev/nvme0n1p2:resume=PARTUUID=${swap_device_guid} noresume root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                sed -i "s:root=/dev/sda2:resume=PARTUUID=${swap_device_guid} noresume root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
            else
                local root_device_guid=$("${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" | grep "PARTITION1, guid:" | awk -F ":" '{print $2}')
                sed -i "s:root=/dev/nvme0n1p2:root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
                sed -i "s:root=/dev/sda2:root=PARTUUID=${root_device_guid}:g" "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ "$ACPI" == "1" ]]; then
                #default select menuentry '1 Cix Sky1 on EVB (ACPI)'
                sed -i '3cset default=1' "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ "$BOARD" == "cloudbook" ]]; then
                sed -i '3cset default=4' "${SCRIPT_DIR}/grub.cfg"
            fi
            if [[ "$DOCKER_MODE" == "docker" ]]; then
                sed -i '3cset default=27' "${SCRIPT_DIR}/grub.cfg"
            fi
            is_post_silicon="true"
            ;;
        esac

        local dtbs=(`find "${PATH_OUT}" -maxdepth 1 -name "*.dtb" | xargs echo`)
        local count=${#dtbs[@]}
        all_dtb=""
        for ((i=0;i<$count;i++))
        do
            dtb=${dtbs[$i]##*/}
            all_dtb="${all_dtb} ${PATH_OUT}/${dtb} /${dtb}"
        done

        if [[ "${BUILD_MODE}" == "debug" ]]; then
            sed -i '14s/.*/        debug \\/' "${SCRIPT_DIR}/grub.cfg"
        fi

        if [[ "${is_post_silicon}" != "true" ]]; then
            if  [[ "$DEBIAN_MODE" != "0" ]]; then
                if  [[ "$FASTBOOT_LOAD" != "nvme" ]]; then
                    sed -i '3cset default="7"' "${SCRIPT_DIR}/grub.cfg"
                    if [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                        sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                    elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                        sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi

                "${SCRIPT_DIR}/tools/mk-part-fat" \
                    -o "${PATH_OUT}/images/boot_os.img" \
                    -s "${boot_size}" \
                    -l "ESP" \
                    "${PATH_OUT}/grub.efi" "/EFI/BOOT/BOOTAA64.EFI" \
                    "${SCRIPT_DIR}/grub.cfg" "/grub/grub.cfg" \
                    "${PATH_OUT}/Image" "/Image" \
                    ${all_dtb} \
                    "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "/rootfs.cpio.gz"

                if  [[ "$FASTBOOT_LOAD" != "nvme" ]]; then
                    sed -i '3cset default="10"' "${SCRIPT_DIR}/grub.cfg"
                    if [[ "$FASTBOOT_LOAD" == "spi" ]]; then
                        sed -i '3cset default="2"' "${SCRIPT_DIR}/grub.cfg"
                    elif [[ "$FASTBOOT_LOAD" == "usb" ]]; then
                        sed -i '3cset default="14"' "${SCRIPT_DIR}/grub.cfg"
                    fi
                fi
            fi
        fi

        if  [[ "$DEBIAN_MODE" == "0" ]]; then
            sed -i '/initrd.img/d' "${SCRIPT_DIR}/grub.cfg"
        fi
        "${SCRIPT_DIR}/tools/mk-part-fat" \
            -o "${PATH_OUT}/images/boot.img" \
            -s "${boot_size}" \
            -l "ESP" \
            "${PATH_OUT}/grub.efi" "/EFI/BOOT/BOOTAA64.EFI" \
            "${SCRIPT_DIR}/grub.cfg" "/grub/grub.cfg" \
            "${PATH_OUT}/Image" "/Image" \
            ${all_dtb} \
            "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "/rootfs.cpio.gz"

        if [[ -e "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz" ]]; then
            "${SCRIPT_DIR}/tools/mk-part-fat" \
                -o "${PATH_OUT}/images/mini-boot.img" \
                -s "${boot_size}" \
                -l "ESP" \
                "${PATH_OUT}/grub.efi" "/EFI/BOOT/BOOTAA64.EFI" \
                "${SCRIPT_DIR}/grub.cfg" "/grub/grub.cfg" \
                "${PATH_OUT}/Image" "/Image" \
                ${all_dtb} \
                "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz" "/rootfs.cpio.gz"
            if [[ -e "${PATH_OUT}/images/cix_flash_all.bin" ]]; then
                local flash_size=$(stat -c "%s" "${PATH_OUT}/images/cix_flash_all.bin")
                local boot_size=$(stat -c "%s" "${PATH_OUT}/images/mini-boot.img")
                local ret_size=$[8*1024*1024-$flash_size]
                echo "flash all bin Size: $flash_size, FF size: $ret_size, boot size: $boot_size"
                dd if=/dev/zero of="${PATH_OUT}/all_ff.bin" bs=1 count=$ret_size status=none | tr '\0' 'F' > /dev/null
                cat "${PATH_OUT}/images/cix_flash_all.bin" "${PATH_OUT}/all_ff.bin" "${PATH_OUT}/images/mini-boot.img" > "${PATH_OUT}/images/cix_flash_all_with_boot.bin"
                echo "total flash size: $(stat -c "%s" "${PATH_OUT}/images/cix_flash_all_with_boot.bin")"
                rm -f "${PATH_OUT}/all_ff.bin"
            fi
        fi
        ;;
    esac

    if [ ! -d /mnt/boot-debian ] ; then
      sudo mkdir /mnt/boot-debian
    fi
    if  [[ "$DEBIAN_MODE" != "0" ]]; then
        if [[ -e "$PATH_OUT/images/boot.img" ]]; then
            if [[ -e $PATH_DEBIAN/boot/initrd.img-$linux_version ]]; then
                sudo mount $PATH_OUT/images/boot.img /mnt/boot-debian
                sudo cp $PATH_DEBIAN/boot/initrd.img-$linux_version /mnt/boot-debian
                sudo umount /mnt/boot-debian
                sudo rmdir /mnt/boot-debian
            else
                echo "No initrd.img found, please check the build"
            fi
        else
            echo "No boot.img found, please check the build"
        fi
    fi
    if [[ -e "${PATH_OUT}/images/boot.img" ]]; then
        img2simg "${PATH_OUT}/images/boot.img" "${PATH_OUT}/images/boot_sparse.img" 1048576
    fi
    if [[ -e "${PATH_OUT}/images/boot_os.img" ]]; then
        img2simg "${PATH_OUT}/images/boot_os.img" "${PATH_OUT}/images/boot_os_sparse.img" 1048576
    fi

    local fs_sdcard="${PATH_OUT}/images/linux-fs.sdcard"
    dd if=/dev/zero of="${fs_sdcard}" bs=1M count=$total_size
    parted -s "${fs_sdcard}" mklabel gpt #msdos #gpt

    if [[ -e "${PATH_OUT}/images/partition-table.img" ]]; then
        dd if="${PATH_OUT}/images/partition-table.img" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=0
    fi
    local boot_offset=`"${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" -p boot | awk '{print $1}'`
    boot_offset=`expr $boot_offset \* 512 / 1024 / 1024`
    echo "boot offset: $boot_offset M bytes"
    dd if="${PATH_OUT}/images/boot.img" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=$boot_offset
    if [[ ${swap_size} -gt 0 ]]; then
        local swap_offset=`"${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" -p swap | awk '{print $1}'`
        swap_offset=`expr $swap_offset \* 512 / 1024 / 1024`
        echo "swap offset: $swap_offset M bytes"
        local swap_img="${PATH_OUT}/swap.img"
        dd if=/dev/zero of="${swap_img}" bs=1M count=$swap_size
        echo mkswap -f "${swap_img}"
        sudo chmod 0600 "${swap_img}"
        mkswap -f "${swap_img}"
        dd if="${swap_img}" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=$swap_offset
        img2simg "${swap_img}" "${PATH_OUT}/images/swap_sparse.img" 1048576
        rm -f "${swap_img}"
    fi
    if [[ -e "${rootfs_ext4}" ]];then
        local rootfs_offset=`"${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table.img" -p root | awk '{print $1}'`
        rootfs_offset=`expr $rootfs_offset \* 512 / 1024 / 1024`
        echo "root offset: $rootfs_offset M bytes"
        dd if="${rootfs_ext4}" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=$rootfs_offset
    fi

    echo "partition-512 table info ----"
    sudo parted "${fs_sdcard}" print
    echo "--------------------------"

    # fs_sdcard="${PATH_OUT}/images/linux-fs-4096.sdcard"
    # dd if=/dev/zero of="${fs_sdcard}" bs=1M count=$total_size
    # parted -s "${fs_sdcard}" mklabel gpt #msdos #gpt

    # if [[ -e "${PATH_OUT}/images/partition-table-4096.img" ]]; then
    #     dd if="${PATH_OUT}/images/partition-table-4096.img" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=0
    # fi
    # local boot_offset=`"${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table-4096.img" -p boot | awk '{print $1}'`
    # boot_offset=`expr $boot_offset \* 4096 / 1024 / 1024`
    # echo "boot offset: $boot_offset M bytes"
    # dd if="${PATH_OUT}/images/boot.img" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=$boot_offset
    # if [ -e "${rootfs_ext4}" ];then
    #     local rootfs_offset=`"${PATH_ROOT}/build-scripts/debian/cix_tool" --flash-tool -d "${PATH_OUT}/images/partition-table-4096.img" -p root | awk '{print $1}'`
    #     rootfs_offset=`expr $rootfs_offset \* 4096 / 1024 / 1024`
    #     echo "root offset: $rootfs_offset M bytes"
    #     dd if="${rootfs_ext4}" of="${fs_sdcard}" conv=notrunc,fsync bs=1M seek=$rootfs_offset
    # fi

    if [[ ! -e "${PATH_OUT}/images/elf" ]]; then
        mkdir -p "${PATH_OUT}/images/elf"
    fi

    #for debug
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/tfa_fw/bl31.elf" "${PATH_OUT}/images/elf/"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/pbl_fw/bl2.elf" "${PATH_OUT}/images/elf/"
    copy_if_exist "${PATH_ROOT}/linux/vmlinux" "${PATH_OUT}/images/elf/"

    #for package tool
    copy_if_exist "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz" "${PATH_OUT}/images/rootfs.cpio.gz"
    copy_if_exist "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz" "${PATH_OUT}/images/mini_rootfs.cpio.gz"
    copy_if_exist "${PATH_OUT}/Image" "${PATH_OUT}/images/Image"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/se_fw/se_fw.bin" "${PATH_OUT}/images/se_fw.bin"
    copy_if_exist "${PATH_EXPORT_FIRMWARE}/pm_fw/pm_fw.bin" "${PATH_OUT}/images/pm_fw.bin"
    copy_if_exist "${PATH_OUT}/pbl_fw.bin" "${PATH_OUT}/images/pbl_fw.bin"
    copy_if_exist "${PATH_OUT}/tf-a.bin" "${PATH_OUT}/images/tf-a.bin"
    copy_if_exist "${PATH_OUT}/tee.bin" "${PATH_OUT}/images/tee.bin"
    copy_if_exist "${PATH_OUT}/SKY1_BL33_UEFI.fd" "${PATH_OUT}/images/SKY1_BL33_UEFI.fd"
    cp -rf "${PATH_OUT}"/*.dtb "${PATH_OUT}/images/"
    copy_if_exist "${PATH_OUT}/grub.efi" "${PATH_OUT}/images/grub.efi"
    copy_if_exist "${SCRIPT_DIR}/grub.cfg" "${PATH_OUT}/images/grub.cfg"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/package-tool.sh" "${PATH_OUT}/"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/bin" "${PATH_OUT}/"
    copy_if_exist "${PATH_CIX_BINARY}/host/packagetool/overlay" "${PATH_OUT}/"

    copy_if_exist "${PATH_ROOT}/build-scripts/debian/boot/EFI" "${PATH_OUT}/images"
    local create_uefi_tool="#!/usr/bin/env bash

# refer to: https://confluence.cixtech.com/pages/viewpage.action?spaceKey=SW&title=UEFI+Flash+Update+Tool
# refer to: https://confluence.cixtech.com/display/SW/UEFI+Burn+Image+Tool

WORKSPACE=\"\$(realpath --no-symlinks \"\$(dirname \"\${BASH_SOURCE[0]}\")\")\"
PATH_DEST=\"\${WORKSPACE}/udisk\"

if [[ \$# -gt 0 ]]; then
    PATH_DEST=\"\$1\"
fi

if [[ ! -e \"\${PATH_DEST}\" ]]; then
    mkdir -p \"\${PATH_DEST}\"
fi
rm -f \${PATH_DEST}/*.*
cp -rf \"\${WORKSPACE}/EFI\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/BurnImage.efi\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/FlashUpdate.efi\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/cix_flash_all\"*\".bin\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/partition-table.img\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/partition-table-4096.img\" \"\${PATH_DEST}\"
cp -f \"\${WORKSPACE}/boot.img\" \"\${PATH_DEST}\"
split -b 512M -d \"\${WORKSPACE}/rootfs.ext4\" \"\${PATH_DEST}/rootfs.ext4.\"
# cp -f \"\${WORKSPACE}/rootfs.ext4\" \"\${PATH_DEST}\"
cd \"\${PATH_DEST}\"
md5sum *.* > md5.txt
cd -

cat > \"\${PATH_DEST}/check-md5.sh\" <<- EOF
#!/usr/bin/env bash
WORKSPACE=\"\\\$(realpath --no-symlinks \"\\\$(dirname \"\\\${BASH_SOURCE[0]}\")\")\"
if [[ \\\$# -lt 1 ]]; then
    MD5_CONFIG=\"\\\${WORKSPACE}/md5.txt\"
else
    MD5_CONFIG=\"\\\$(realpath --no-symlinks \"\\\$1\")\"
fi
echo \"\\\${MD5_CONFIG}\"
if [[ ! -e \"\\\${MD5_CONFIG}\" ]]; then
    echo \"\\\${MD5_CONFIG} does not exist.\"
    exit 1
fi
PATH_DEST=\"\\\$(dirname \"\\\${MD5_CONFIG}\")\"
cat \"\\\${MD5_CONFIG}\" | while IFS= read -r line
do
    data=(\\\$line)
    file=\"\\\${PATH_DEST}/\\\${data[1]}\"
    value=(\\\$(md5sum \"\\\${file}\"))
    echo \"check: \\\${file}\"
    if [[ \"\\\${data[0]}\" != \"\\\${value[0]}\" ]]; then
        echo \"FAIL: md5 \\\${value[0]} is changed for \\\${file}\"
        exit 1
    fi
done
if [[ \"\\\$?\" != \"1\" ]]; then
    echo \"SUCCESS\"
fi
EOF
chmod +x \"\${PATH_DEST}/check-md5.sh\"

cat > \"\${PATH_DEST}/check-md5.bat\" <<- EOF
@echo off
set WORKSPACE=%~dp0
for /f \"tokens=*\" %%l in (%WORKSPACE%\\md5.txt) do (
    for /F \"tokens=1,2 delims= \" %%a in (\"%%l\") do (
        echo check: %WORKSPACE%%%b
        setlocal enabledelayedexpansion
        set value=
        for /F \"skip=1 delims=\" %%m in ('CertUtil -hashfile %WORKSPACE%%%b MD5') do (
            if not defined value (set value=%%m)
        )
        if not \"%%a\"==\"!value: =!\" (
            echo \"FAIL: md5 !value: =! is changed for %WORKSPACE%%%b\"
            endlocal
            goto end
        )
        endlocal
    )
)
echo \"SUCCESS\"
:end
pause
EOF
chmod +x \"\${PATH_DEST}/check-md5.bat\"
"
    echo "${create_uefi_tool}" > "${PATH_OUT}/images/uefi_tool.sh"
    chmod +x "${PATH_OUT}/images/uefi_tool.sh"
}

readonly DO_DESC_clean="clean rootfs and linux-fs.sdcard"
do_clean() {
    rm -f "${PATH_OUT}/images/rootfs.ext4"
    rm -f "${PATH_OUT}/linux-fs.sdcard"
    rm -rf "${PATH_OUT}/images/boot.img"
}

readonly DO_DESC_flash="flash images onto the device"
do_flash() {
    case "$PLATFORM" in
    ("cix")
        local path="${PATH_OUT}/images"
        local file=${INPUT}
        if [[ -d "${file}" ]]; then
            path=${file}
            file="${path}/partition-table.img"
        elif [[ -d "${PRIVATE_WORKSPACE}/${file}" ]]; then
            path="${PRIVATE_WORKSPACE}/${file}"
            file="${path}/partition-table.img"
        fi
        if [[ ${#file} -lt 1 ]]; then
            file=${PATH_OUT}/images/partition-table.img
        fi
        echo "gpt image: ${file}"
        # if [[ -e "${PATH_OUT}/images/cix_flash_all.bin" ]]; then
        #     sudo ${PATH_ROOT}/build-scripts/debian/cix_tool -i "${PATH_OUT}/images/cix_flash_all.bin"
        # elif [[ -e "${PATH_OUT}/images/cix_flash_all_rsa_pr.bin" ]]; then
        #     sudo ${PATH_ROOT}/build-scripts/debian/cix_tool -i "${PATH_OUT}/images/cix_flash_all_rsa_pr.bin"
        # fi

        sleep 1
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --enter-fastboot
        sleep 3

        if [[ -e "${path}/cix_flash_all_rsa_proto.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all_rsa_proto.bin"
        elif [[ -e "${path}/cix_flash_all_rsa_pr.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all_rsa_pr.bin"
        elif [[ -e "${path}/cix_flash_all.bin" ]]; then
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash bootloader "${path}/cix_flash_all.bin"
        else
            echo "no bios can flash."
        fi

        if [[ -e "${file}" ]]; then
            echo "fastboot flash gpt ${file}"
            sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash gpt "${file}"
            ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f "${file}" --dump | grep name | while read line; do
                local name=$(echo ${line} | awk '{print $4}')
                echo $name
                if [[ -e "${path}/${name}_sparse.img" ]]; then
                    echo "fastboot flash ${name} ${path}/${name}_sparse.img"
                    sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/${name}_sparse.img"
                elif [[ ${name} == "root" ]]; then
                    if [[ -e "${path}/rootfs_sparse.ext4" ]]; then
                        echo "fastboot flash ${name} ${path}/rootfs_sparse.ext4"
                        sudo "${PATH_ROOT}/build-scripts/debian/fb/fastboot" flash ${name} "${path}/rootfs_sparse.ext4"
                    fi
                else
                    echo "no image can flash for partition ${name}"
                fi
            done
        fi

        sleep 1
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --exit-fastboot
        ;;
    esac
}

readonly DO_DESC_run="run rootfs and kernel on qemu"
do_run() {
    qemu-system-aarch64 -machine virt,virtualization=true,gic-version=3  \
        -cpu cortex-a57 \
        -smp 2 \
        -kernel "${PATH_OUT}/Image" \
        -initrd "${PATH_OUT}/rootfs_debian.cpio.gz" \
        -m size=2G \
        -append "root=/dev/ram rdinit=/sbin/init" \
        -nographic

    #qemu-system-aarch64 -machine virt,kernel_irqchip=on,gic-version=3 -cpu cortex-a57 -m 2G -bios "${PATH_CIX_BINARY}/device/images/QEMU_EFI.fd" -hda "${PATH_OUT}/images/boot.img" -nographic

    #ESC
    #Boot Manager
    #EFI Internal Shell
    #f0:
    #
}

readonly DO_DESC_disk="create the disk image with gpt, boot, root"
do_disk() {
    local path="${PATH_OUT}/images"
    local file=${INPUT}
    if [[ -d "${file}" ]]; then
        echo "${file} is dir"
        path=${file}
        file="${path}/linux-fs.sdcard"
    elif [[ -d "${PRIVATE_WORKSPACE}/${file}" ]]; then
        path="${PRIVATE_WORKSPACE}/${file}"
        file="${path}/linux-fs.sdcard"
    fi

    if [[ ${#file} -lt 1 ]]; then
        file=${path}/linux-fs.sdcard
    fi
    echo "image: ${file}"

    local images=""
    if [[ -e "${path}/boot.img" ]]; then
        images="${images} --image-file ${path}/boot.img --image-name boot --image-type-uuid c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
    fi

    if [[ -e "${path}/swap.img" ]]; then
        images="${images} --image-file ${path}/swap.img --image-name swap --image-type-uuid 0657fd6d-a4ab-43c4-84e5-0933c84b4f4f"
    else
        local swap_size=${SWAP_SIZE:-0}
        if [[ ${swap_size} -gt 0 ]]; then
            local swap_img="${path}/swap.img"
            rm -f "${swap_img}"
            dd if=/dev/zero of="${swap_img}" bs=1M count=$swap_size
            echo mkswap -f "${swap_img}"
            sudo chmod 0600 "${swap_img}"
            mkswap -f "${swap_img}"
            images="${images} --image-file ${swap_img} --image-name swap --image-type-uuid 0657fd6d-a4ab-43c4-84e5-0933c84b4f4f"
        fi
    fi

    if [[ -e "${path}/root.img" ]]; then
        images="${images} --image-file ${path}/root.img --image-name root --image-type-uuid b921b045-1df0-41c3-af44-4c6f280d3fae --image-uuid $(uuidgen)"
        #images="${images} --image-file ${path}/root.img --image-name root1 --image-type-uuid b921b045-1df0-41c3-af44-4c6f280d3fae --image-uuid $(uuidgen)"
    else
        if [[ -e "${path}/rootfs.ext4" ]]; then
            images="${images} --image-file ${path}/rootfs.ext4 --image-name root --image-type-uuid b921b045-1df0-41c3-af44-4c6f280d3fae --image-uuid $(uuidgen)"
        fi
    fi

    sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt --create -f ${file} ${images}
    sudo chown $USER:$USER ${file}
    #fdisk ${file} -l
}

readonly DO_DESC_extract="extract the disk image"
do_extract() {
    local file=${INPUT}
    if [[ ! -f "${file}" ]]; then
        if [[ -f "${PRIVATE_WORKSPACE}/${file}" ]]; then
            file="${PRIVATE_WORKSPACE}/${file}"
        fi
    fi
    if [[ ${#file} -lt 1 ]]; then
        file=${PATH_OUT}/images/linux-fs.sdcard
    fi

    if [[ -e "${file}" ]]; then
        echo "image: ${file}"
        sudo ${PATH_ROOT}/build-scripts/debian/cix_tool --release-tool --gpt -f ${file} --extract ${PRIVATE_WORKSPACE}/extracted
        echo "${file} is extracted to the path ${PRIVATE_WORKSPACE}/extracted"
        sudo chown $USER:$USER "${PRIVATE_WORKSPACE}/extracted" -R
    fi
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
