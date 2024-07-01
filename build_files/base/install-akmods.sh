#!/bin/bash

set -ouex pipefail

if [[ -n "${COREOS_TYPE:-}" ]]; then
    curl -L -o /etc/yum.repos.d/fedora-coreos-pool.repo \
        https://raw.githubusercontent.com/coreos/fedora-coreos-config/testing-devel/fedora-coreos-pool.repo
fi

# Nvidia for gts/stable - nvidia
if [[ "${COREOS_TYPE}" == "nvidia" ]]; then
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
fi

curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Everyone
rpm-ostree install \
    /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
    /tmp/akmods-rpms/kmods/*xone*.rpm \
    /tmp/akmods-rpms/kmods/*openrazer*.rpm \
    /tmp/akmods-rpms/kmods/*wl*.rpm \
    /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm
    # /tmp/akmods-rpms/kmods/*framework-laptop*.rpm

# All but Asus
if grep -qv "asus" <<< "${AKMODS_FLAVOR}"; then
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*evdi*.rpm
fi

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

# ZFS for gts/stable
if [[ -n "${COREOS_TYPE:-}" ]]; then
    rpm-ostree install /tmp/akmods-rpms/kmods/zfs/*.rpm \
                       pv
    depmod -a -v "${KERNEL}".x86_64
    echo "zfs" > /usr/lib/modules-load.d/zfs.conf
fi
