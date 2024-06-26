#!/bin/bash

set -ouex pipefail

curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
        /tmp/akmods-rpms/kmods/*xone*.rpm \
        /tmp/akmods-rpms/kmods/*openrazer*.rpm \
        /tmp/akmods-rpms/kmods/*wl*.rpm \
        /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
        /tmp/akmods-rpms/kmods/*framework-laptop*.rpm
fi
if grep -qv "asus" <<< "${AKMODS_FLAVOR}"; then
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*evdi*.rpm
fi
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

if [[ "${COREOS_TYPE}" == "nvidia" ]]; then
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
fi

if [[ "${AKMODS_FLAVOR}" =~ "coreos" ]]; then
    curl -Lo /etc/yum.repos.d/ublue-os-ucore-fedora.repo \
        https://copr.fedorainfracloud.org/coprs/ublue-os/ucore/repo/fedora/ublue-os-ucore-fedora.repo
    KERNEL_FOR_DEPMOD="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
    rpm-ostree install /tmp/coreos/akmods-rpms/*.rpm \
                       /tmp/coreos/akmods-rpms/zfs/*.rpm \
                       pv
    depmod -A "${KERNEL_FOR_DEPMOD}"
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ublue-os-ucore-fedora.repo
fi
