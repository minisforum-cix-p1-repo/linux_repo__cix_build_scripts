#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#
#sudo apt-get install libarchive-tools xorriso jigdo-file

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

prepare_debs() {
    local timestamp=$1

    local path_debian_debs_dir="${PATH_DEBIAN}/debs"
    sudo mkdir -p "${path_debian_debs_dir}"

    if [ "$DEBIAN_MODE" == "1" ]; then
        sudo cp -pf $PRE_COMPILE_DEB/*/*.deb $PATH_DEB
        if [[ "${DOCKER_MODE}" == "docker" ]]; then
            if [[ ! -e "$PRE_COMPILE_DEB/docker" ]]; then
                echo "error, miss docker referenced debs under $PRE_COMPILE_DEB/docker"
                exit 1
            fi
        else
            cd $PATH_DEB
            sudo rm -rf containerd.io_*.deb docker-*.deb
            cd -
        fi
    fi

    # Download chromium deb packages from nexus to PATH_DEB
    if [[ "$DEBIAN_MODE" == "1" ]] && [[ "${DOCKER_MODE}" != "docker" ]]; then
        cix_download -s "linux-weekly:cix_master-Chromium%2Flatest/chromium-common_128.0.6613.84-1~deb12u1_arm64.deb" -f ${PATH_DEB}/chromium-common_128.0.6613.84-1~deb12u1_arm64.deb
        cix_download -s "linux-weekly:cix_master-Chromium%2Flatest/chromium_128.0.6613.84-1~deb12u1_arm64.deb" -f ${PATH_DEB}/chromium_128.0.6613.84-1~deb12u1_arm64.deb
        cix_download -s "debian12_dev_env:dl_debian%2Flibcolord-gtk1_0.3.0-3.1_arm64.deb" -f ${PATH_DEB}/libcolord-gtk1_0.3.0-3.1_arm64.deb
        cix_download -s "debian12_dev_env:dl_debian%2Fgnome-bluetooth-common_3.34.5-10_all.deb" -f ${PATH_DEB}/gnome-bluetooth-common_3.34.5-10_all.deb
        cix_download -s "debian12_dev_env:dl_debian%2Flibgnome-bluetooth13_3.34.5-10_arm64.deb" -f ${PATH_DEB}/libgnome-bluetooth13_3.34.5-10_arm64.deb
        cix_download -s "debian12_dev_env:dl_debian%2Fbudgie-control-center-data_1.2.0-2_all.deb" -f ${PATH_DEB}/budgie-control-center-data_1.2.0-2_all.deb
        cix_download -s "debian12_dev_env:dl_debian%2Fbudgie-control-center_1.2.0-2_arm64.deb" -f ${PATH_DEB}/budgie-control-center_1.2.0-2_arm64.deb
        cix_download -s "debian12_dev_env:dl_debian%2Fdbus_1.14.10-1~deb12u1_arm64.deb" -f ${PATH_DEB}/dbus_1.14.10-1~deb12u1_arm64.deb
    fi

    sudo cp -pf ${PATH_DEB}/*.deb ${path_debian_debs_dir}/
    sudo rm -f "${PATH_DEBIAN}/lib/modules/${linux_version}/build"

    local debList=($(find "${path_debian_debs_dir}" -name *.deb))
    if [ "$DEBIAN_MODE" == "5" -o "$DEBIAN_MODE" == "8" ]; then
	#There is for openkylin-beta2 and kylin-v10
	local install_script="#!/bin/bash 

WORKSPACE=\"\$(realpath --no-symlinks \"\$(dirname \"\${BASH_SOURCE[0]}\")\")\"

if [[ -e \$(ls \${WORKSPACE}/cix-openkylin-beta2*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-openkylin-beta2*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-common-misc*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-common-misc*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-gpu-umd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-gpu-umd*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-mesa*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-mesa*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-unit-test*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-unit-test*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-npu-umd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-npu-umd*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-ltp*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-ltp*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-audio-dsp*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-audio-dsp*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-libglvnd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-libglvnd*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-libdrm*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-libdrm*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-cpipe*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-cpipe*.deb
fi

if [[ -e \$(ls \${WORKSPACE}/cix-npu-driver*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-npu-driver*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-noe-umd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-noe-umd*.deb
fi

if [[ -e \$(ls \${WORKSPACE}/cix-npu-onnxruntime*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-npu-onnxruntime*.deb
fi

if [[ -e \$(ls \${WORKSPACE}/cix-mnn*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-mnn*.deb
fi

if [[ -e \$(ls \${WORKSPACE}/cix-llama-cpp*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-llama-cpp*.deb
fi
# do not produce initrd in chroot environment
mv /etc/kernel/postinst.d/initramfs-tools /etc/kernel/initramfs-tools.bak
if [ -n \"\$(ls \${WORKSPACE}/linux-*.deb)\" ]; then
    dpkg -i \${WORKSPACE}/linux-*.deb
fi
if [ -n \"\$(ls \${WORKSPACE}/cix-*-driver*.deb)\" ]; then
    dpkg -i \${WORKSPACE}/cix-*-driver*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-wlan*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-wlan*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-firmware*.deb 2>/dev/null) ]]; then
    dpkg -i --force-overwrite \${WORKSPACE}/cix-firmware*.deb
fi

# TODO: diable pipewire
apt purge -y pipewire
"
    elif [ "$DEBIAN_MODE" == "7" ]; then
	# spec for openkylin-alpha
	local install_script="#!/bin/bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

WORKSPACE=\"\$(realpath --no-symlinks \"\$(dirname \"\${BASH_SOURCE[0]}\")\")\"


if [[ -L "/usr/lib/policykit-1/polkit-agent-helper-1" ]]; then
    chmod 5755 /usr/lib/policykit-1/polkit-agent-helper-1
fi
export DEBIAN_FRONTEND=noninteractive
# only install specific cix deb packages

if [[ -e \$(ls \${WORKSPACE}/cix-openkylin-adapter*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-openkylin-adapter*.deb
fi

if [[ -e \$(ls \${WORKSPACE}/cix-xwayland*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-xwayland*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-mesa*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-mesa*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-gpu-umd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-gpu-umd*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-ltp*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-ltp*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-audio-dsp*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-audio-dsp*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-libglvnd*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-libglvnd*.deb
fi

# do not trigger to produce initrd in chroot environment
mv /etc/kernel/postinst.d/initramfs-tools /etc/kernel/initramfs-tools.bak
if [ -n \"\$(ls \${WORKSPACE}/linux-*.deb)\" ]; then
    dpkg -i \${WORKSPACE}/linux-*.deb
fi
if [ -n \"\$(ls \${WORKSPACE}/cix-*-driver*.deb)\" ]; then
    dpkg -i \${WORKSPACE}/cix-*-driver*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-wlan*.deb 2>/dev/null) ]]; then
    dpkg -i \${WORKSPACE}/cix-wlan*.deb
fi
if [[ -e \$(ls \${WORKSPACE}/cix-firmware*.deb 2>/dev/null) ]]; then
    dpkg -i --force-overwrite \${WORKSPACE}/cix-firmware*.deb
fi
"
    else
    local install_script="#!/bin/bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

WORKSPACE=\"\$(realpath --no-symlinks \"\$(dirname \"\${BASH_SOURCE[0]}\")\")\"

# install cix deb packages

# debs=\`find \"/debs\" -maxdepth 1 -name \"*.deb\" | xargs echo\`
# arr=(\$debs)
# len=\${#arr[@]}
# for ((i=0;i<\$len;i++))
# do
#    apt install \${arr[\$i]}
# done

if [[ -L "/usr/lib/policykit-1/polkit-agent-helper-1" ]]; then
    chmod 5755 /usr/lib/policykit-1/polkit-agent-helper-1
fi
if [ $DEBIAN_MODE == 6 ]; then
    if [[ -e \$(ls \${WORKSPACE}/cix-gstreamer*.deb 2>/dev/null) ]]; then
        rm -rf \${WORKSPACE}/cix-gstreamer*.deb 
    fi

    find  \${WORKSPACE}  -type f \( ! -name "cix*" -a ! -name "linux*" \) -exec rm {} \;

    if [[ -e \$(ls \${WORKSPACE}/cix-firmware*.deb 2>/dev/null) ]]; then
        dpkg -i --force-overwrite \${WORKSPACE}/cix-firmware*.deb
    fi
    rm -rf  /etc/kernel/postinst.d/zz-update-grub 
fi
export DEBIAN_FRONTEND=noninteractive
apt -y --allow-downgrades install \${WORKSPACE}/*.deb

if [ \$? -ne 0 ];then
    echo \"============================================================\"
    echo \"\"
    echo \"Chroot the rootfs to install package failed\"
    echo \"Please check the logs\"
    echo \"\"
    echo \"============================================================\"
    exit 22
fi

#systemctl mask swap.target
#systemctl enable cix_resume.service
#systemctl enable cix_resume_prepare.service
"
fi
    echo "${install_script}" > "${PATH_DEB}/install.sh"
    chmod +x "${PATH_DEB}/install.sh"
    sudo cp "${PATH_DEB}/install.sh" "${path_debian_debs_dir}/install.sh"
}

function mergeRootfs() {
    local timestamp=$1
    local line=""

    sudo cp $PATH_DEBIAN/etc/skel/.bashrc $PATH_DEBIAN/root
    sudo sed -i '5,9d' $PATH_DEBIAN/root/.bashrc
    line=`sudo sed -n "/export PATH=/=" "${PATH_DEBIAN}/root/.bashrc"`
    if [[ "$line" == "" ]]; then
        sudo sh -c "echo 'export PATH=/usr/share/cix/bin:\$PATH' >> ${PATH_DEBIAN}/root/.bashrc"
    fi

    prepare_debs $timestamp

    if [[ -e "${PATH_ROOT}/debian12/script/busybox" ]]; then
        sudo cp -fp "${PATH_ROOT}/debian12/script/busybox" "${PATH_DEBIAN}/bin"
    fi

    sudo touch ${PATH_DEBIAN}/home/init
    sudo chmod 777 ${PATH_DEBIAN}/home/init
    sudo ln -sf /bin/busybox ${PATH_DEBIAN}/home/init
    sudo ln -sf /bin/bash ${PATH_DEBIAN}/bin/sh

    if [[ "${BOARD}" == "fpga" ]]; then
        sudo sh -c "echo 'if [ ! -d "/proc/1" ]; then mount -t proc proc /proc; fi' >> ${PATH_DEBIAN}/etc/profile"
        sudo sh -c "echo 'if [ ! -d "/sys/devices" ]; then mount -t sysfs sysfs /sys; fi' >> ${PATH_DEBIAN}/etc/profile"
        sudo sh -c "echo 'if [ ! -e "/dev/console" ]; then mount --rbind /dev /dev; fi' >> ${PATH_DEBIAN}/etc/profile"
        sudo sh -c "echo 'if [ ! -d "/sys/kernel/debug/slab" ]; then mount -t debugfs none /sys/kernel/debug; fi' >> ${PATH_DEBIAN}/etc/profile"
    fi

    if [[ "${SYSTEMD_TARGET:-graphical}" == "multi-user" ]]; then
        cat > "${PATH_OUT}/systemd_target.sh" <<- EOF
#!/bin/bash
chown -R man: /var/cache/man/
systemctl set-default ${SYSTEMD_TARGET:-graphical}.target
EOF
        sudo cp -fp "${PATH_OUT}/systemd_target.sh" "${PATH_DEBIAN}/systemd_target.sh"
        sudo chmod +x "${PATH_DEBIAN}/systemd_target.sh"
        sudo chroot "${PATH_DEBIAN}" "/systemd_target.sh"
        sudo rm -f "${PATH_DEBIAN}/systemd_target.sh"
    fi
}

function make_rootfs() {
    local rootfs_ext4="$1"
    if [ -e "${rootfs_ext4}" ];then
        rm -f "${rootfs_ext4}"
    fi

    if [[ -e "${PATH_DEBIAN}/home/${USER}" ]]; then
        sudo rm -rf "${PATH_DEBIAN}/home/${USER}"
    fi
    local debianSize=`sudo du ${PATH_DEBIAN} -d 0 -k | sudo awk -F ' ' '{print $1}'`
    debianSize=`expr $debianSize \* 13 / 10`
    if [[ ${debianSize} -lt 1024 ]]; then
        totalsize='10240'
    elif [[ ${debianSize} -lt 10240 ]]; then
        totalsize=`expr $debianSize \* 50 / 10`
    elif [[ ${debianSize} -lt 102400 ]]; then
        totalsize=`expr $debianSize \* 25 / 10`
    elif [[ ${debianSize} -lt 1024000 ]]; then
        totalsize=`expr $debianSize \* 20 / 10`
    else
        totalsize=`expr $debianSize + ${ROOT_FREE_SIZE:-4096000}`
    fi
    #totalsize=`expr $totalsize + 2048000` #add 2G
    if [[ "$BOARD" == "fpga" ]] || [[ "$BOARD" == "emu" ]]; then
        if [[ ${totalsize} -gt 9216000 ]]; then #must less than 9G
            echo -e "warning: ${RED}rootfs size is too large ${totalsize} ${NORMAL}"
            totalsize=9216000
        fi
    elif [[ "$BOARD" == "cloudbook" ]]; then
        totalsize=32768000 #32G
    fi

    local count=`expr $totalsize / 4`
    sudo dd if=/dev/zero of="${rootfs_ext4}" bs=4k count=$count
    sudo mkfs.ext4 -U "${uuid}" -F -i 4096 "${rootfs_ext4}" -d "${PATH_DEBIAN}"
    sudo fsck.ext4 -pvfD "${rootfs_ext4}"
    sudo chown ${USER}:${USER} "${rootfs_ext4}"
    img2simg "${rootfs_ext4}" "${PATH_OUT}/images/rootfs_sparse.ext4" 1048576

    if [[ -e "${PATH_ROOT}/../fvp/tc2/output/debian/deploy/tc2/debian.img" ]]; then
        cp -fp "${rootfs_ext4}" "${PATH_ROOT}/../fvp/tc2/output/debian/deploy/tc2/debian.img"
    fi
}

function make_iso() {
    local orig_iso="${HOME}/dl/dl_debian/debian-12.11.0-arm64-DVD-1.iso"
    local new_iso="${PATH_OUT}/images/cix_debian.iso"

    local iso_tmp_path="${PATH_OUT}/iso_tmp"
    local efi_img="${iso_tmp_path}/efi.img"
    local new_files="${iso_tmp_path}/iso_unpacked"

    local deb_config="${iso_tmp_path}/config-deb"
    local part_img_ready=1

    if [[ -e "${iso_tmp_path}" ]]; then
        sudo rm -rf "${iso_tmp_path}"
    fi
    mkdir "${iso_tmp_path}"

    cix_download -s "debian12_dev_env:dl_debian%2Fdebian-12.11.0-arm64-DVD-1.iso" -b cix_debian_base.iso
    if [[ -e "${PATH_ROOT}/ext/mirror/cix_debian_base.iso" ]]; then
        orig_iso="${PATH_ROOT}/ext/mirror/cix_debian_base.iso"
    fi

    if [[ ! -e "${orig_iso}" ]]; then
        echo "file ${orig_iso} does not exist"
        exit 1
    fi

    local start_block=$(/sbin/fdisk -l "$orig_iso" | fgrep "$orig_iso"2 | awk '{print $2}')
    local block_count=$(/sbin/fdisk -l "$orig_iso" | fgrep "$orig_iso"2 | awk '{print $4}')
    if test "$start_block" -gt 0 -a "$block_count" -gt 0 2>/dev/null
    then
        dd if="$orig_iso" bs=512 skip="$start_block" count="$block_count" of="$efi_img"
    else
        echo "Cannot read plausible start block and block count from fdisk" >&2
        part_img_ready=0
    fi

    mkdir "${new_files}"
    bsdtar -C "${new_files}" -xf "${orig_iso}"
    #xorriso -osirrox on -indev "${orig_iso}" -extract / "${new_files}"
    #gunzip -c "${new_files}/dists/bookworm/main/binary-arm64/Packages.gz" > "${iso_tmp_path}/Packages"

    chmod +w -R "${new_files}"

    if [[ "$ACPI" == "0" ]]; then
        if [[ -e "${PATH_OUT}/Image" ]]; then
            cp -f "${PATH_OUT}/Image" "${new_files}/install.a64/vmlinuz"
            cp -f "${PATH_OUT}/Image" "${new_files}/install.a64/gtk/vmlinuz"
        fi
        if [[ -e "${PATH_OUT}/sky1-${BOARD}-iso.dtb" ]]; then
            cp -f "${PATH_OUT}/sky1-${BOARD}-iso.dtb" "${new_files}/install.a64/sky1-${BOARD}.dtb"
        fi
        sed -i s/evb/${BOARD}/g $PATH_ROOT/build-scripts/debian/iso_grub.cfg
        cp -f "${PATH_ROOT}/build-scripts/debian/iso_grub.cfg" "${new_files}/boot/grub/grub.cfg"
    fi

        local preseed="#_preseed_V1

#### Advanced options
### Running custom commands during the installation
# d-i preseeding is inherently not secure. Nothing in the installer checks
# for attempts at buffer overflows or other exploits of the values of a
# preconfiguration file like this one. Only use preconfiguration files from
# trusted locations! To drive that home, and because it's generally useful,
# here's a way to run any shell command you'd like inside the installer,
# automatically.

# Individual additional packages to install
d-i preseed/early_command string umount /media
d-i base-installer/kernel/image string linux-image-${linux_version}
"

    echo "${preseed}" > "${PATH_ROOT}/debian12/script/preseed.cfg"
    preseed="d-i pkgsel/include string pulseaudio pulseaudio-module-bluetooth smplayer chromium ffmpeg power-profiles-daemon perl memtester bonnie++ alsa-ucm-conf mpich libfdk-aac2 fprintd glmark2-x11 glmark2-wayland glmark2-es2-x11 glmark2-es2-wayland glmark2-es2-drm glmark2-drm iperf3 lm-sensors libdrm-etnaviv1 libdrm-freedreno1 libdrm-tegra0 libva-glx2 libwayland-bin"

    # debs=`find "$PRE_COMPILE_DEB" -maxdepth 2 -name "*.deb" | xargs echo`
    # arr=($debs)
    # len=${#arr[@]}
    # for ((i=0;i<$len;i++))
    # do
        # local deb=${arr[$i]}
        # local package_name=`dpkg-deb -W "${deb}" | awk '{print $1}'`
        # local first_letter=${package_name:0:1}
        # if [[ ! -e "${new_files}/pool/main/${first_letter}/${package_name}" ]]; then
            # mkdir "${new_files}/pool/main/${first_letter}/${package_name}"
        # fi
        # cp -f "${deb}" "${new_files}/pool/main/${first_letter}/${package_name}/"
        # preseed="$preseed $package_name"
    # done

    cd $new_files/pool/main/m/meta-gnome3/
    sudo chmod a+w .
    fakeroot dpkg-deb -R gnome-core_43+1_arm64.deb gnome-core
    sed -i s/"pipewire-audio,"/""/g gnome-core/DEBIAN/control
    sed -i s/"Version: 1:43+1"/"Version: 1:43+1+cix"/g gnome-core/DEBIAN/control
    fakeroot dpkg-deb -b gnome-core gnome-core_43+1_arm64.deb
    rm -rf gnome-core
    sudo chmod a-w .
    cd -

    debs=`find "${PATH_DEB}" -maxdepth 1 -name "*.deb" | xargs echo`
    arr=($debs)
    len=${#arr[@]}
    for ((i=0;i<$len;i++))
    do
        local deb=${arr[$i]}
        local package_name=`dpkg-deb -W "${deb}" | awk '{print $1}'`
        local first_letter=${package_name:0:1}
        if [[ ! -e "${new_files}/pool/main/${first_letter}/${package_name}" ]]; then
            mkdir "${new_files}/pool/main/${first_letter}/${package_name}"
        fi
        cp -f "${deb}" "${new_files}/pool/main/${first_letter}/${package_name}/"
        preseed="$preseed $package_name"
    done
    echo "${preseed}" >> "${PATH_ROOT}/debian12/script/preseed.cfg"
    local preseed2="
d-i preseed/late_command string in-target apt-get -y remove pipewire-pulse wireplumber;in-target apt-get -y autoremove;in-target update-initramfs -c -k ${linux_version} -b /boot"
    echo "${preseed2}" >> "${PATH_ROOT}/debian12/script/preseed.cfg"

    if [[ "$ACPI" == "0" ]]; then
        if [[ -e "${new_files}/install.a64/initrd.gz" ]]; then
            gunzip "${new_files}/install.a64/initrd.gz"
            if [[ -e "${PATH_OUT}/iso_initrd" ]]; then
                sudo rm -rf "${PATH_OUT}/iso_initrd"
            fi
            mkdir "${PATH_OUT}/iso_initrd"
            cd "${PATH_OUT}/iso_initrd"
            sudo cpio -i < "${new_files}/install.a64/initrd" || true
            sudo cp -f "${PATH_ROOT}/debian12/script/preseed.cfg" ./
            sudo rm -rf ./lib/modules/*
            dpkg-deb -R $PATH_DEB/linux-image-${linux_version}_*.deb $PATH_OUT/linux-image
            sudo cp -rf ${PATH_OUT}/linux-image/lib/modules/* ./lib/modules/
            sudo rm -rf ./lib/modules/${linux_version}/extra/*
            sudo find . | sudo cpio --quiet -o -H newc > "${new_files}/install.a64/initrd"
            cd -
            sudo chown $USER:$USER "${new_files}/install.a64/initrd"
            gzip "${new_files}/install.a64/initrd"
        fi
        if [[ -e "${new_files}/install.a64/gtk/initrd.gz" ]]; then
            gunzip "${new_files}/install.a64/gtk/initrd.gz"
            if [[ -e "${PATH_OUT}/iso_initrd" ]]; then
                sudo rm -rf "${PATH_OUT}/iso_initrd"
            fi
            mkdir "${PATH_OUT}/iso_initrd"
            cd "${PATH_OUT}/iso_initrd"
            sudo cpio -i < "${new_files}/install.a64/gtk/initrd" || true
            sudo cp -f "${PATH_ROOT}/debian12/script/preseed.cfg" ./
            sudo rm -rf ./lib/modules/*
            sudo cp -rf ${PATH_OUT}/linux-image/lib/modules/* ./lib/modules/
            sudo rm -rf $PATH_OUT/linux-image
            sudo rm -rf ./lib/modules/${linux_version}/extra/*
            sudo find . | sudo cpio --quiet -o -H newc > "${new_files}/install.a64/gtk/initrd"
            cd -
            sudo chown $USER:$USER "${new_files}/install.a64/gtk/initrd"
            gzip "${new_files}/install.a64/gtk/initrd"
        fi
      else
        gunzip "${new_files}/install.a64/initrd.gz"
        gunzip "${new_files}/install.a64/gtk/initrd.gz"
        cd "${PATH_ROOT}/debian12/script"
        echo "preseed.cfg" | cpio -H newc -o -A -F "${new_files}/install.a64/initrd"
        echo "preseed.cfg" | cpio -H newc -o -A -F "${new_files}/install.a64/gtk/initrd"
        cd -
        gzip "${new_files}/install.a64/initrd"
        gzip "${new_files}/install.a64/gtk/initrd"
    fi

    touch "${deb_config}"
    cat > "${deb_config}" <<- EOF
# A config-deb file.

# Points to where the unpacked ISO is.
Dir {
    ArchiveDir "${new_files}";
};

# Sets the top of the .deb directory tree.
TreeDefault {
   Directory "pool/";
};

# The location for a Packages file.
BinDirectory "pool/main" {
   Packages "dists/bookworm/main/binary-arm64/Packages";
};

# We are only interested in .deb files (.udeb for udeb files).
Default {
   Packages {
       Extensions ".deb";
    };
};
EOF
    apt-ftparchive generate "${deb_config}"

    sed -i '/MD5Sum:/,$d' ${new_files}/dists/bookworm/Release
    apt-ftparchive release ${new_files}/dists/bookworm >> ${new_files}/dists/bookworm/Release

    set +E
    cd "${new_files}"
    md5sum `find ! -name "md5sum.txt" -follow -type f` > md5sum.txt
    #find -follow -type f ! -name md5sum.txt ! -name debian -print0 | xargs -0 md5sum > md5sum.txt
    cd -
    set -E

    sudo chmod u-w,g-w,o-w -R "${new_files}"

    #create the new ISO image
    test "$part_img_ready" = 1 && \
    xorriso -as mkisofs \
        -r -V 'Debian 12.9.0 arm64 n' \
        -o "$new_iso" \
        -J -joliet-long -cache-inodes \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -append_partition 2 0xef "$efi_img" \
        -partition_cyl_align all \
        "$new_files"
}

function make_tc2_image() {
    echo "Creating MMC bootable debian image"

    # MMC Bootable image
    OUT_IMG="${PATH_OUT}/debian_tc2.img"

    size_in_mb() {
            local size_in_bytes
            size_in_bytes=$(wc -c $1)
            size_in_bytes=${size_in_bytes%% *}
            echo $((size_in_bytes / 1024 / 1024 + 1))
    }

    # Debian Raw filesystem
    DEBIAN_IMG="${PATH_OUT}/images/rootfs.ext4"
    DEBIAN_SIZE=$(size_in_mb ${DEBIAN_IMG})
    IMAGE_LEN=$((DEBIAN_SIZE + 2 ))
    DEBIAN_SIZE_G=`expr $DEBIAN_SIZE / 1000 + 1`

    #echo "DEBIAN_SIZE: $DEBIAN_SIZE"
    #echo "DEBIAN_SIZE_G: $DEBIAN_SIZE_G"

    # measured in MBytes
    PART1_START=1
    PART1_END=$((PART1_START + DEBIAN_SIZE))

    PARTED="sudo parted -a min "

    # Create an empty disk image file
    dd if=/dev/zero of=$OUT_IMG bs=1M count=${DEBIAN_SIZE_G}K

    # Create a partition table
    $PARTED $OUT_IMG unit s mktable gpt

    # Create partitions
    SEC_PER_MB=$((1024*2))
    $PARTED $OUT_IMG unit s mkpart debian ext4 $((PART1_START * SEC_PER_MB)) $((PART1_END * SEC_PER_MB - 1))

    # Assemble all the images into one final image (There is one debian image as of Today)
    dd if=$DEBIAN_IMG of=$OUT_IMG bs=1M seek=${PART1_START} conv=notrunc

    if [[ -e "${HOME}/dl/fvp_tc2_package/cix_fvp_tc2/debian.img" ]]; then
        cp -f "${OUT_IMG}" "${HOME}/dl/fvp_tc2_package/cix_fvp_tc2/debian.img"
    fi
}

copy_optee_rootfs() {
    pkg_Name="cix-optee"
    local build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
    if [[ "$TEE_TYPE" == "optee" ]] && [[ -e "${build_deb_dir}" ]]; then
        sudo cp -rf "${build_deb_dir}/bin" "${PATH_DEBIAN}"
        sudo cp -rf "${build_deb_dir}/etc" "${PATH_DEBIAN}"
        sudo cp -rf "${build_deb_dir}/usr" "${PATH_DEBIAN}"
    fi
}

readonly DO_DESC_build="build and generate the debian root file system"
do_build() {
    local timestamp=0
    OLD_IFS="$IFS"
    IFS=","
    local record=(`find_and_get_line "\"debian-config\"" "${PATH_OUT}/.compile.csv"`)
    IFS="$OLD_IFS"

    uuid=$(uuidgen)

    if [[ ${#record[@]} -gt 2 ]]; then
        timestamp=${record[2]}
    fi

    if [[ -e "${PATH_DEBIAN}" ]]; then
        sudo rm -rf "${PATH_DEBIAN}"
    fi

    if [[ ! -e "${PATH_DEBIAN}" ]]; then
        timestamp=0
        mkdir -p "${PATH_DEBIAN}"
        if [[ -e "${PATH_ROOT}/build-scripts/debian/optimize_rootfs.sh" ]]; then 
            cp -f "${PATH_ROOT}/build-scripts/debian/optimize_rootfs.sh" "${PATH_OUT}/images/rootfs_bu.sh"
        fi

        #0: without debian, 1: gnome+xfce, 2: gnome, 3: xfce, 4: console
        case "$DEBIAN_MODE" in
        ("0") #buildroot
            sudo rm -rf "${PATH_DEBIAN}"
            mkdir -p "${PATH_DEBIAN}"
            echo "debian mode: ${DEBIAN_MODE}, without debian. and will use the buildroot as the rootfs"
            cd "${PATH_DEBIAN}"
            sudo cpio -i < "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz"
            copy_optee_rootfs
            #sudo cpio -i < "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz"
            cd -
            make_rootfs "${PATH_OUT}/images/rootfs.ext4"
            #make_tc2_image
            replace_or_add_line "\"debian-config\"" "\"debian-config\",\"${DEBIAN_MODE}\",$(date +%s)" "${PATH_OUT}/.compile.csv"
            return
            ;;
        ("1") #gnome + xfce
            echo "debian: gnome + xfce"
            cix_download -s "debian12_dev_env:${CIX_VERSION}%2Fdebian_desktop_gnome_xfce.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            if [[ -e "${PATH_ROOT}/build-scripts/debian/growroot.sh" ]] && [[ -e "${PATH_DEBIAN}/etc/initramfs-tools/scripts/init-top/growroot.sh" ]]; then
                sudo cp "${PATH_ROOT}/build-scripts/debian/growroot.sh" "${PATH_DEBIAN}/etc/initramfs-tools/scripts/init-top/growroot.sh"
                sudo chmod +x "${PATH_DEBIAN}/etc/initramfs-tools/scripts/init-top/growroot.sh"
            fi
            sudo chown -R 6:12 ${PATH_DEBIAN}/var/cache/man
            ;;
        ("2") #gnome
            echo "debian: gnome"
            cix_download -s "debian12_dev_env:${CIX_VERSION}%2Fdebian_desktop_gnome.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        ("3") #xfce
            echo "debian: xfce"
            cix_download -s "debian12_dev_env:${CIX_VERSION}%2Fdebian_desktop_xfce.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        ("4") #console
            echo "debian: console"
            cix_download -s "debian12_dev_env:${CIX_VERSION}%2Fdebian_console.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        ("5") #Openkylin V2.0 Release
            echo "debian: Openkylin V2.0 Release"
            cix_download -s "debian12_dev_env:${CIX_Kylin_VERSION}%2Fdebian_openkylin2.0-release.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
	        sudo cp -rf ${PATH_ROOT}/component/cix_opensource/npu/ai_demo/linux/cix-stablediffusion-demo ${PATH_DEBIAN}/opt/cix/
            sudo chown -R 1000:1000 ${PATH_DEBIAN}/opt/cix/cix-stablediffusion-demo
            ;;

        ("6") #deepin
            echo "debian: deepin"
            cix_download -s "debian12_dev_env:${CIX_Deepin_VERSION}%2Fdebian_deepin.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        ("7") #openkylin-alpha
            echo "debian: openkylin-alpha"
            cix_download -s "debian12_dev_env:${CIX_Kylin_VERSION}%2Fdebian_openkylin.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        ("8") #kylin-v10-sp1
            echo "debian: kylin-v10-sp1 rc4 with kylin-aiassistant "
            cix_download -s "customer-iso:/kylin-v10-rc4.tgz" -d "${PATH_DEBIAN}" -b "cix_debian_base.tgz" -p sudo
            ;;
        esac

        if [[ $(cat "${PATH_DEBIAN}/etc/passwd" | grep "cix:") != "" ]]; then
            if [[ -e "${PATH_ROOT}/tmp" ]]; then
                sudo rm -rf "${PATH_ROOT}/tmp"
            fi
            mkdir "${PATH_ROOT}/tmp"
            local script="#!/bin/bash
userdel -r cix
useradd -m -G sudo mini
echo mini:mini | chpasswd
usermod -a -G users,cdrom,floppy,audio,dip,video,plugdev,netdev,bluetooth mini -s /bin/bash
sed -i 's/cix-localhost/mini-localhost/g' /etc/hosts
sed -i 's/cix-localhost/mini-localhost/g' /etc/hostname
sed -i 's/AutomaticLogin = cix/AutomaticLogin = mini/g' /etc/gdm3/daemon.conf
"
            echo "${script}" > "${PATH_ROOT}/tmp/install.sh"
            chmod +x "${PATH_ROOT}/tmp/install.sh"
            sudo mv "${PATH_ROOT}/tmp/install.sh" "${PATH_DEBIAN}/"
            sudo chroot "${PATH_DEBIAN}" "/install.sh"
            sudo rm -f "${PATH_DEBIAN}/install.sh"
        fi

        if [[ ! -e "${PATH_DEBIAN}/sys" ]]; then
            sudo mkdir "${PATH_DEBIAN}/sys"
        fi
        if [[ ! -e "${PATH_DEBIAN}/proc" ]]; then
            sudo mkdir "${PATH_DEBIAN}/proc"
        fi
        if [[ ! -e "${PATH_DEBIAN}/tmp" ]]; then
            sudo mkdir "${PATH_DEBIAN}/tmp"
        fi

        sudo rm -rf "${PATH_DEBIAN}/lib/modules"/*
    fi
    if [[ "$DEBIAN_MODE" == "0" ]]; then
        echo "debian mode: ${DEBIAN_MODE}, without debian. and will use the buildroot as the rootfs"
        cd "${PATH_DEBIAN}"
        sudo cpio -i < "${PATH_CIX_BINARY}/device/images/rootfs.cpio.gz"
        copy_optee_rootfs
        #sudo cpio -i < "${PATH_CIX_BINARY}/device/images/mini_rootfs.cpio.gz"
        cd -
        make_rootfs "${PATH_OUT}/images/rootfs.ext4"
        #make_tc2_image
        replace_or_add_line "\"debian-config\"" "\"debian-config\",\"${DEBIAN_MODE}\",$(date +%s)" "${PATH_OUT}/.compile.csv"
        return
    fi

    mergeRootfs $timestamp

    # if [[ ! -e "${PATH_OUT}/rootfs_debian.cpio.gz" ]]; then
    #     cd "$PATH_DEBIAN"
    #     sudo find . | sudo cpio -o -H newc | sudo gzip -9 > "${PATH_OUT}/rootfs_debian.cpio.gz"
    #     cd -
    #     sudo chown ${USER}:${USER} "${PATH_OUT}/rootfs_debian.cpio.gz"
    # fi

    #make ramdisk.img
    if [[ ! -e "${PATH_OUT}/ramdisk.img" ]]; then
        case "$PLATFORM" in
        (*)
            ;;
        esac
    fi

    #make_rootfs "${PATH_OUT}/images/rootfs_base.ext4"

    local debList=($(find "${PATH_DEBIAN}/debs" -name *.deb))
    if [[ ${#debList[@]} -gt 0 ]]; then
        ls "${PATH_DEBIAN}/debs"
        local script="#!/bin/bash
export http_proxy=\"${http_proxy:-}\"
export https_proxy=\"${https_proxy:-}\"
export ftp_proxy=\"${ftp_proxy:-}\"
export no_proxy=\"localhost,localhost:*,127.*,*.cixcomputing.com,*.cixtech.com,10.128.*\"

if [[ \"\$(dpkg -l | grep \"chromium-common\")\" != \"\" ]]; then
    apt purge -y chromium-common
fi
if [[ \"\$(dpkg -l | grep \"chromium\")\" != \"\" ]]; then
    apt purge -y chromium
fi
/debs/install.sh
if [ \$? -ne 0 ]; then
  exit 22
fi
systemctl mask NetworkManager-wait-online.service
systemctl mask systemd-networkd-wait-online.service
systemctl set-default ${SYSTEMD_TARGET:-graphical}.target
update-initramfs -c -k ${linux_version} -b /boot
    "

        if [[ -e "${PATH_ROOT}/tmp" ]]; then
            sudo rm -rf "${PATH_ROOT}/tmp"
        fi
        mkdir "${PATH_ROOT}/tmp"
        echo "${script}" > "${PATH_ROOT}/tmp/install.sh"
        chmod +x "${PATH_ROOT}/tmp/install.sh"
        sudo sh -c "echo 'UUID=$uuid / ext4 errors=remount-ro 0 1' >> $PATH_DEBIAN/etc/fstab"
        sudo sed -i '98,100d' $PATH_DEBIAN/usr/share/initramfs-tools/hooks/fsck
        sudo sed -i '99i\copy_exec /sbin/fsck.ext4' $PATH_DEBIAN/usr/share/initramfs-tools/hooks/fsck

        sudo cp "${PATH_ROOT}/tmp/install.sh" "${PATH_DEBIAN}/"
	      if [[ "$DEBIAN_MODE" == "5" ]]; then  #Running update-initramfs in OpenKylin will hang.
		        sed -i '/update-initramfs/d' "${PATH_DEBIAN}"/install.sh
	      fi
        sudo chroot "${PATH_DEBIAN}" "/install.sh"
        entries='

#Libreoffice force Skia software rendering
export SAL_ENABLESKIA=1
'
        if [ "$DEBIAN_MODE" == "5" -o "$DEBIAN_MODE" == "6" -o "$DEBIAN_MODE" == "8" ]; then
entries+='
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_LANG=zh_CN.UTF-8
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
'
        fi
        target_file="$PATH_DEBIAN/etc/profile"

        while IFS= read -r line; do
            if [ -z "$line" ]; then
                continue
            fi

            if ! grep -Fxq "$line" "$target_file"; then
                sudo sh -c "echo '$line' >> '$target_file'"
            fi
        done <<< "$entries"

        sudo rm -f "${PATH_DEBIAN}/install.sh"
        sudo rm -rf "${PATH_DEBIAN}/debs"

        sudo rm -rf "${PATH_ROOT}/tmp"

        NEW_HOSTNAME="mini-localhost"
        sudo sed -i -E "s/^(127\.0\.1\.1\s+).*/\1$NEW_HOSTNAME/" $PATH_DEBIAN/etc/hosts

        make_rootfs "${PATH_OUT}/images/rootfs.ext4"
    fi

    if [[ "${ISO_INSTALLER:-0}" == "1" ]]; then
        cd $PATH_OUT/debs
        rm -rf audio-chat-gradio*.deb chatbot-gradio*.deb rag-chat-* image-multiChat-*
        cd -
        make_iso
    fi

    rm -rf $PATH_DEB/install.sh
    cat > $PATH_DEB/install.sh <<- 'EOF'
sudo apt -y install ./*.deb
EOF
    chmod a+x $PATH_DEB/install.sh
    tar -czf $PATH_OUT/cix-upgrade-debs.tgz -C $PATH_DEB .

    #make_tc2_image

    replace_or_add_line "\"debian-config\"" "\"debian-config\",\"${DEBIAN_MODE}\",$(date +%s)" "${PATH_OUT}/.compile.csv"
}

readonly DO_DESC_iso="debian iso"
do_iso() {
    make_iso
}

readonly DO_DESC_tc2="debian image for tc2"
do_tc2() {
    sudo rm -rf "${PATH_DEBIAN}"
    mkdir -p "${PATH_DEBIAN}"

    cix_download -s "debian12_dev_env:${CIX_VERSION}%2Fdebian_desktop_xfce.tgz" -d "${PATH_DEBIAN}" -p sudo

    if [[ ! -e "${PATH_DEBIAN}/sys" ]]; then
        sudo mkdir "${PATH_DEBIAN}/sys"
    fi
    if [[ ! -e "${PATH_DEBIAN}/proc" ]]; then
        sudo mkdir "${PATH_DEBIAN}/proc"
    fi
    if [[ ! -e "${PATH_DEBIAN}/tmp" ]]; then
        sudo mkdir "${PATH_DEBIAN}/tmp"
    fi

    #sudo rm -rf "${PATH_DEBIAN}/lib/modules"/*

    make_rootfs "${PATH_OUT}/images/rootfs.ext4"

    make_tc2_image
}

readonly DO_DESC_clean="clean the debian images"
do_clean() {
    local tc2_img="${PATH_OUT}/debian_tc2.img"
    local iso_img="${PATH_OUT}/images/cix_debian.iso"
    local cpio_img="${PATH_OUT}/rootfs_debian.cpio.gz"
    if [[ -e "${tc2_img}" ]]; then
        rm -f "${tc2_img}"
    fi
    if [[ -e "${iso_img}" ]]; then
        rm -f "${iso_img}"
    fi
    if [[ -e "${cpio_img}" ]]; then
        rm -f "${cpio_img}"
    fi
    if [[ -e "${PATH_OUT}/ramdisk.img" ]]; then
        rm -f "${PATH_OUT}/ramdisk.img"
    fi
    if [[ -e "${PATH_DEBIAN}" ]]; then
        sudo rm -rf "${PATH_DEBIAN}"
    fi
    if [[ -e "${PATH_OUT}/images/rootfs.ext4" ]]; then
        rm -f "${PATH_OUT}/images/rootfs.ext4"
    fi
}

readonly DO_DESC_create_env="install the environment for creating the debian footfs"
do_create_env() {
    sudo apt-get install binfmt-support qemu qemu-user-static debootstrap multistrap debian-archive-keyring
}

readonly DO_DESC_prepare="prepare the tmp files while creating the debian rootfs"
do_prepare() {
    local path="${PATH_DEBIAN}"
    if [[ ! -e "${path}" ]]; then
        sudo debootstrap --arch=arm64 --foreign bullseye debian http://mirrors.163.com/debian/
    fi
    pushd "${path}"
    sudo cp "${PATH_ROOT}/build-scripts/debian/postinstall_console.sh" ./
    sudo cp "${PATH_ROOT}/build-scripts/debian/postinstall_desktop.sh" ./
    if ! mountpoint -q proc; then sudo mount proc -t proc proc; fi
    if ! mountpoint -q dev; then sudo mount devtmpfs -t devtmpfs dev; fi
    if ! mountpoint -q sys; then sudo mount sysfs -t sysfs sys; fi
    sudo chroot .
    popd
}

readonly DO_DESC_cleanup="cleanup the tmp files while creating the debian rootfs"
do_cleanup() {
    local path="${PATH_DEBIAN}"
    pushd "${path}"
    if mountpoint -q proc; then sudo umount proc; fi
    if mountpoint -q dev; then sudo umount dev; fi
    if mountpoint -q sys; then sudo umount sys; fi

    if [[ -e "postinstall_console.sh" ]]; then
        sudo rm postinstall_console.sh #usr/bin/qemu*
    fi
    if [[ -e "postinstall_desktop.sh" ]]; then
        sudo rm postinstall_desktop.sh #usr/bin/qemu*
    fi
    popd
}

readonly DO_DESC_create="create the debian rootfs"
do_create() {
    local path="${PATH_DEBIAN}"
    if [[ ! -e "${path}" ]]; then
        do_prepare
        exit 0
    fi
    pushd "${path}"
    sudo chroot .
    popd
}

readonly DO_DESC_run="run debian and kernel on qemu"
do_run() {
    qemu-system-aarch64 -machine virt,virtualization=true,gic-version=3  \
        -cpu cortex-a57 \
        -smp 2 \
        -kernel "${PATH_OUT}/Image" \
        -initrd "${PATH_OUT}/rootfs_debian.cpio.gz" \
        -m size=4G \
        -append "root=/dev/ram rdinit=/sbin/init" \
        -nographic
}

readonly DO_DESC_qemu="run debian ios installer on qemu"
do_qemu() {
    local qemu_elf="${PATH_ROOT}/tools/cix_binary/device/images/QEMU_EFI.fd"
    #local iso="${PATH_ROOT}/debian-12.1.0-arm64-netinst.iso"
    #local iso="${PATH_ROOT}/cix-debian-12-arm64.iso"
    local iso="${PATH_OUT}/images/cix_debian.iso"
    local hda="${PATH_OUT}/hda.img"

    if [[ ! -e "$iso" ]]; then
        echo "iso ($iso) dose not exist."
        exit 0
    fi

    if [[ ! -e "$hda" ]]; then
        #qemu-img create -f qcow2 $hda 4G
        qemu-img create $hda 16G
    fi

    #bring up from hda.img
    sudo qemu-system-aarch64 \
        -M virt-2.12 -smp 4 -m 8G -cpu cortex-a57 \
        -bios $qemu_elf -device ramfb \
        -device qemu-xhci,id=xhci -usb \
        -device usb-kbd -device usb-mouse -device usb-tablet -k en-us \
        -device virtio-blk,drive=system,bootindex=0 \
        -drive if=none,id=system,format=raw,media=disk,file=$hda \
        -device usb-storage,drive=install \
        -drive if=none,id=install,format=raw,media=cdrom,file=$iso \
        -device virtio-net,disable-legacy=on,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 -vnc :3
}


readonly DO_DESC_modify="run a script to modify the rootfs"
do_modify() {
    local path="${INPUT:-}"
    if [[ ! -e "${path}" ]]; then
        path="${PATH_OUT}/overlay"
        if [[ ! -e "${path}" ]]; then
            mkdir -p ${path}
            #nexus download directory
            cix_download -s "debian12_dev_env:${CIX_VERSION}%2Foverlay.tgz" -d "${path}"
        fi
    fi

    if [[ -e "${path}" ]]; then
        path="$(realpath --no-symlinks "${path}")"
        path="-d ${path}"
    else
        path=""
    fi

    if [[ ! -e "${PATH_OUT}/images/rootfs.ext4" ]]; then
        echo -e "${BOLD}${RED}the rootfs (${PATH_OUT}/images/rootfs.ext4) does not exist. ${NORMAL}"
        return
    fi

    "${PATH_ROOT}/build-scripts/debian/optimize_rootfs.sh" -r ${PATH_OUT}/images/rootfs.ext4 ${path}

    case "$DDR_MODEL" in
    axi-4G)
        "${PATH_ROOT}/tools/sw_tools_open/host/bin2hex/cix_fpga_bin_hex" -bh "${PATH_OUT}/images/rootfs.ext4" "${PATH_OUT}/hex/rootfs.ext4.hex" 32
        ;;
    ddr*)
        ;;
    ("axi-16G")
        ;;
    esac
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
