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
    rpm-ostree install /tmp/nvidia/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm
    # shellcheck disable=SC1091
    source /tmp/nvidia/akmods-rpms/kmods/nvidia-vars
    if [[ "${BASE_IMAGE_NAME}" == "kinoite" ]]; then
        VARIANT_PKGS="supergfxctl-plasmoid supergfxctl"
    elif [[ "${BASE_IMAGE_NAME}" == "silverblue" ]]; then
        VARIANT_PKGS="gnome-shell-extension-supergfxctl-gex supergfxctl"
    else
        VARIANT_PKGS=""
    fi
    rpm-ostree install \
        "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}-{,cuda-,devel-,kmodsrc-,power-}${NVIDIA_FULL_VERSION}" \
        "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}-libs.i686" \
        "nvidia-container-toolkit nvidia-vaapi-driver ${VARIANT_PKGS}" \
        "/tmp/nvidia/akmods-rpms/kmods/kmod-${NVIDIA_PACKAGE_NAME}-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${FEDORA_MAJOR_VERSION}.rpm"
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/nvidia-container-toolkit.repo
    systemctl enable ublue-nvctk-cdi.service
    semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
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
