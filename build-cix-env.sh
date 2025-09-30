#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

readonly DO_DESC_build="build env cnofig"
do_build() {
# build deb package
pkg_Name="cix-env"
build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
rm -rf $build_deb_dir
install_dir_config=${build_deb_dir}/etc
mkdir -p $install_dir_config
if [ ! -d $build_deb_dir/etc/environment.d ] ; then mkdir $build_deb_dir/etc/environment.d;fi
cat > "$build_deb_dir/etc/environment.d/cix_env.conf" <<- EOF
KWIN_COMPOSE=O2ES
QT_OPENGL=es2
GDK_GL=gles
GST_GL_API=gles2
GST_PLUGIN_PATH_1_0=/usr/share/cix/lib/gstreamer-1.0:/usr/lib/aarch64-linux-gnu/gstreamer-1.0
LD_LIBRARY_PATH=/usr/share/cix/lib
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
CLUTTER_PAINT=disable-clipped-redraws
EOF

if [ ! -d $build_deb_dir/etc/profile.d ] ; then mkdir $build_deb_dir/etc/profile.d;fi
cat > "$build_deb_dir/etc/profile.d/cix-conf.sh" <<- 'EOF'
export GST_PLUGIN_PATH_1_0=/usr/share/cix/lib/gstreamer-1.0:/usr/lib/aarch64-linux-gnu/gstreamer-1.0
export LD_LIBRARY_PATH=/usr/share/cix/lib
export PATH=/usr/share/cix/bin:$PATH:/sbin
EOF

rc_local="$build_deb_dir/etc/rc.local"
touch $rc_local
sh -c "echo '#!/bin/bash' >> $rc_local"
if [[ "$BOARD" == "cloudbook" ]]; then
    if [[ -e "${PATH_OUT}/debs/cix-bluez_1.0.0_arm64.deb" ]]; then
        sh -c "echo '/usr/share/cix/bin/hciattach /dev/ttyAMA0 qca -t120 3000000 flow 2>/dev/null &' >> $rc_local"
    fi
    sh -c "echo 'insmod /lib/modules/${linux_version}/extra/wlan_cnss_core_pcie.ko' >> $rc_local"
    sh -c "echo 'insmod /lib/modules/${linux_version}/extra/wlan.ko' >> $rc_local"
    sh -c "echo 'insmod /lib/modules/${linux_version}/extra/amvx.ko hw_ncores=1' >> $rc_local"
    sh -c "echo 'echo 0x5 >/sys/class/misc/mali0/device/core_mask' >> $rc_local"
fi
if [[ "$DOCKER_MODE" == "docker" ]]; then
    sh -c "echo 'echo always_on > /sys/class/misc/mali0/device/power_policy' >> $rc_local"
    sh -c "echo 'echo performance > /sys/class/misc/mali0/device/devfreq/15000000.gpu/governor' >> $rc_local"
    sh -c "echo 'echo performance > /sys/class/devfreq/14230000.vpu/governor' >> $rc_local"
fi

sh -c "echo 'if lspci | grep -i \"VGA compatible controller: Advanced Micro Devices\" > /dev/null; then' >> $rc_local"
sh -c "echo '    modprobe ttm' >> $rc_local"
sh -c "echo '    modprobe gpu-sched' >> $rc_local"
sh -c "echo '    modprobe drm_buddy' >> $rc_local"
sh -c "echo '    modprobe drm_ttm_helper' >> $rc_local"
sh -c "echo '    modprobe video' >> $rc_local"
sh -c "echo '    modprobe amdgpu' >> $rc_local"
sh -c "echo 'fi' >> $rc_local"

sh -c "echo 'chmod 0666 /sys/class/remoteproc/remoteproc*/name' >> $rc_local"
sh -c "echo 'chmod 0666 /sys/class/remoteproc/remoteproc*/state' >> $rc_local"
sh -c "echo 'exit 0' >> $rc_local"
chmod +x $rc_local

if [[ ! -e $build_deb_dir/DEBIAN ]]; then
    mkdir -p $build_deb_dir/DEBIAN
fi
cat > $build_deb_dir/DEBIAN/postinst <<- EOF
#!/bin/sh
set -e

if [[ -e "/etc/default/cpufrequtils" ]]; then
    sh -c "sed -i 's/performance/schedutil/g' /etc/default/cpufrequtils"
fi

if [ -e /usr/share/applications/chromium.desktop ];then
    sh -c "sed -i '131s/.*/Exec=chromium --ozone-platform=wayland/' /usr/share/applications/chromium.desktop"
fi

exit 0
EOF
chmod a+x $build_deb_dir/DEBIAN/postinst

mkdir -p $build_deb_dir/lib/udev/rules.d
touch ${build_deb_dir}/lib/udev/rules.d/99-rpmsg.rules
sh -c "echo 'SUBSYSTEM==\"rpmsg\" MODE=\"0666\"' >> ${build_deb_dir}/lib/udev/rules.d/99-rpmsg.rules"

if [[ "${BOARD}" == "cloudbook" ]]; then
    cat > "${PATH_ROOT}/99-cix-drm.rules" <<- EOF
SUBSYSTEM=="drm",ACTION=="change",DEVPATH=="/devices/platform/soc@0/*.disp-controller/drm/card*"  RUN+="/bin/blackscreen.sh"
EOF
    mv "${PATH_ROOT}/99-cix-drm.rules" "$build_deb_dir/lib/udev/rules.d/99-cix-drm.rules"
    chmod 777 "$build_deb_dir/lib/udev/rules.d/99-cix-drm.rules"


    cat > "${PATH_ROOT}/blackscreen.sh" <<- EOF
#!/bin/bash

busctl --machine=cix@.host --user set-property org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig org.gnome.Mutter.Displ
ayConfig PowerSaveMode i 3
sleep 1
busctl --machine=cix@.host --user set-property org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig org.gnome.Mutter.Displ
ayConfig PowerSaveMode i 0
EOF
    mkdir $build_deb_dir/bin
    mv "${PATH_ROOT}/blackscreen.sh" "$build_deb_dir/bin/blackscreen.sh"
    chmod 777 "$build_deb_dir/bin/blackscreen.sh"
fi

mkdir -p "$build_deb_dir/usr/lib/modprobe.d"
cp -f "${PATH_ROOT}/debian12/script/blacklist.conf" "$build_deb_dir/usr/lib/modprobe.d/blacklist.conf"
chmod 777 "$build_deb_dir/usr/lib/modprobe.d/blacklist.conf"
mkdir -p "$build_deb_dir/etc/modprobe.d"
cp -fp "${PATH_ROOT}/debian12/script/blacklist.conf" "$build_deb_dir/etc/modprobe.d/"
chmod 777 "$build_deb_dir/etc/modprobe.d/blacklist.conf"

create_cix_deb "${pkg_Name}"

}

do_clean() {
  echo "nothing to do"
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
