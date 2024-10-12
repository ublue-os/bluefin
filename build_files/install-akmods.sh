#!/bin/bash

set -ouex pipefail

# Nvidia for gts/stable - nvidia
if [[ "${NVIDIA_TYPE}" == "nvidia" ]]; then
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
fi

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Everyone
rpm-ostree install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm
    # /tmp/akmods-rpms/kmods/*framework-laptop*.rpm

# rpmfusion dependent kmods
rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
rpm-ostree install \
    broadcom-wl /tmp/akmods/kmods/*wl*.rpm \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release

# ZFS for gts/stable
if [[ ${AKMODS_FLAVOR} =~ "coreos" ]]; then
    rpm-ostree install pv /tmp/akmods-zfs/kmods/zfs/*.rpm
    depmod -a -v "${KERNEL}"
    echo "zfs" > /usr/lib/modules-load.d/zfs.conf
fi
