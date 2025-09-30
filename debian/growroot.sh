#!/bin/sh

# Grow root. This will expand the root partition to the total disk
grow_root() {
    echo "auto grow the root size"
	local uuid=$(echo $(cat /proc/cmdline) | awk -F "root=" '{print $2}' | awk -F "=" '{print $2}' | awk '{print $1}')
	case $uuid in
	*-*-*-*-*)
		local root=$(blkid | grep "$uuid" | awk -F ":" '{print $1}')
		local device=$root
		case $device in
		*[0-9])
			device=${device:0:${#device}-1}
			case $device in
			*p)
				device=${device:0:${#device}-1}
				;;
			esac
			;;
		esac
		echo "root uuid: ${uuid}, device: ${device}, root: ${root}"

		if [ ! -e /tmp/rootfs ]; then
			mkdir -p /tmp/rootfs
		fi
		mount $root /tmp/rootfs
		local dfSize=$(($(df | grep $root | awk '{print $2}') * 1024 / 1000 / 1000 / 1000))
		umount /tmp/rootfs
		local fdiskSize=$(fdisk -l | grep root | awk -F "G" '{print $1}' | awk '{print $4}')
		local totalSize=$(fdisk -l | grep "Disk ${device}" | awk -F ": " '{print $2}' | awk '{print $1}')
		dfSize=$(echo $dfSize | awk -F "." '{print $1}')
		fdiskSize=$(echo $fdiskSize | awk -F "." '{print $1}')
		totalSize=$((${totalSize} * 512 / 1000 / 1000 / 1000))
		echo "dfSize=${dfSize}, fdiskSize=${fdiskSize} totalSize=${totalSize}"
		if [ $dfSize -lt $(($fdiskSize - 50)) ]; then
			e2fsck -f -y $root
			resize2fs $root ${fdiskSize}G
			echo "resize $root to ${fdiskSize}G only"
			return
		fi
		if [ $dfSize -lt $(($totalSize - 50)) ]; then
			/bin/cix-gpt -f $device --expand-root auto
			echo "expand root partition"
		else
			echo "no work to expand root"
		fi
		;;
	*)
		echo "invalid uuid: ${uuid}"
		return
		;;
	esac
}

grow_root > /run/initramfs/growroot.log

