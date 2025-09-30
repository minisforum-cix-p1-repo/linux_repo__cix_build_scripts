#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

DEPENDENT_MODULES="build-kernel.sh"

readonly DO_DESC_build="build csi-dma driver and embed into debian system"
do_build() {

  # build deb package
  pkg_Name="cix-csidma-driver"
  build_deb_dir=${PATH_OUT_DEB_PACKAGES}/${pkg_Name}
  rm -rf ${build_deb_dir}
  install_dir=${build_deb_dir}/lib/modules/${linux_version}/extra
  mkdir -p ${install_dir}

  export ARCH=arm64
  export SENSOR_DIR=${PATH_ROOT}/linux/drivers/media/i2c/cix/lt7911uxc
  export DRV_DIR=${PATH_ROOT}/linux/drivers/media/platform/cix/csi_dma
  export KSRC=${PATH_LINUX}

  echo "copy the sensor ko"
  SNESOR_MODULE_NAME=(lt7911uxc.ko)
  cd "${SENSOR_DIR}"
  for i in ${SNESOR_MODULE_NAME[@]};
  do
    if [ -f ${SENSOR_DIR}/$i ]; then
      cp ${SENSOR_DIR}/$i "${install_dir}"
    else
      echo error $i module not exist
      exit
    fi
  done

  echo "copy the csi_dma ko"
  cd "${DRV_DIR}"
  CSI_DMA_MODULE_NAME=(csi_dma.ko csi_mipi_csi2.ko csi_mipi_dphy_hw.ko csi_mipi_dphy_rx.ko csi_rcsu_hw.ko)
  for i in ${CSI_DMA_MODULE_NAME[@]};
  do
    if [ -f ${DRV_DIR}/$i ]; then
      cp ${DRV_DIR}/$i "${install_dir}"
    else
      echo error $i module not exist
      exit
    fi
  done
  rm -rf ${build_deb_dir}/lib/modules/${linux_version}/extra/lt7911uxc.ko
  create_cix_deb "${pkg_Name}"
  # finish build deb package
}

readonly DO_DESC_clean="clean csi-dma driver project"
do_clean() {
    local KMD_DRV_DIR=${PATH_ROOT}/linux/drivers/media/platform/cix/csi_dma
    make -C "${KMD_DRV_DIR}" clean
}

source "$(dirname ${BASH_SOURCE[0]})/framework.sh"
