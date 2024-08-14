#!/bin/bash

set -ouex pipefail

# if [[ -n "${NVIDIA_TYPE:-}" ]]; then
#     curl -L -o /etc/yum.repos.d/fedora-coreos-pool.repo \
#         https://raw.githubusercontent.com/coreos/fedora-coreos-config/testing-devel/fedora-coreos-pool.repo
# fi

# Nvidia for gts/stable - nvidia
if [[ "${NVIDIA_TYPE}" == "nvidia" ]]; then
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
fi

curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Everyone
rpm-ostree install \
    /tmp/akmods/kmods/*xpadneo*.rpm \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm \
    /tmp/akmods/kmods/*wl*.rpm \
    /tmp/akmods/kmods/*v4l2loopback*.rpm
    # /tmp/akmods-rpms/kmods/*framework-laptop*.rpm

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

# ZFS for gts/stable
if [[ ${AKMODS_FLAVOR} =~ "coreos" ]]; then
    rpm-ostree install pv /tmp/akmods-zfs/kmods/zfs/*.rpm
    depmod -a -v "${KERNEL}"
    echo "zfs" > /usr/lib/modules-load.d/zfs.conf
fi
