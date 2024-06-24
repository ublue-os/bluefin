#!/bin/bash

set -ouex pipefail

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ -z ${COREOS_TAG:-} ]]; then
    curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
    if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
            /tmp/akmods-rpms/kmods/*xone*.rpm \
            /tmp/akmods-rpms/kmods/*openrazer*.rpm \
            /tmp/akmods-rpms/kmods/*wl*.rpm \
            /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm
    fi
    if grep -qv "asus" <<< "${AKMODS_FLAVOR}"; then
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*evdi*.rpm
    fi
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
elif [[ ${COREOS_TAG} =~ "coreos" ]]; then
    curl -Lo /etc/yum.repos.d/ublue-os-ucore-fedora.repo \
        https://copr.fedorainfracloud.org/coprs/ublue-os/ucore/repo/fedora/ublue-os-ucore-fedora.repo
    KERNEL_FOR_DEPMOD="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
    find /tmp/coreos/rpms
    rpm-ostree install /tmp/coreos/rpms/kmods/ublue-os-ucore-addons-*.rpm
    rpm-ostree install /tmp/coreos/rpms/kmods/zfs/*.rpm pv
    depmod -A ${KERNEL_FOR_DEPMOD}
    # if [[ "${COREOS_TAG}" =~ "coreos-nv" ]]; then
    #     curl -Lo /etc/yum.repos.d/negativo17-fedora-nvidia.repo https://negativo17.org/repos/fedora-nvidia.repo
    #     rpm-ostree install /tmp/coreos/rpms/kmods/nvidia/ublue-os-ucore-nvidia-*.rpm
    #     sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/nvidia-container-toolkit.repo
    #     rpm-ostree install \
    #         /tmp/coreos/rpms/kmods/nvidia/kmod-nvidia-*.rpm \
    #         nvidia-driver-cuda \
    #         nvidia-container-toolkit
    #     sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/nvidia-container-toolkit.repo
    #     sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-nvidia.repo.
    # fi
fi
