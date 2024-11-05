#!/usr/bin/bash

set -eoux pipefail

if [[ "${IMAGE_NAME}" =~ hwe ]]; then
    echo "HWE image detected, installing HWE packages"
else
    echo "Standard image detected, skipping HWE packages"
    exit 0
fi

# Asus/Surface for HWE
curl -Lo /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo \
    https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-$(rpm -E %fedora)/lukenukem-asus-linux-fedora-$(rpm -E %fedora).repo

curl -Lo /etc/yum.repos.d/linux-surface.repo \
        https://pkg.surfacelinux.com/fedora/linux-surface.repo

# Asus Firmware
git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware
cp -rf /tmp/asus-firmware/* /usr/lib/firmware/
rm -rf /tmp/asus-firmware

ASUS_PACKAGES=(
    asusctl
    asusctl-rog-gui
)

SURFACE_PACKAGES=(
    iptsd
    libcamera
    libcamera-tools
    libcamera-gstreamer
    libcamera-ipa
    pipewire-plugin-libcamera
)

rpm-ostree install \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"
