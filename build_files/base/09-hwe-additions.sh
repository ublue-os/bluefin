#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

if [[ "${IMAGE_NAME}" =~ hwe ]]; then
    echo "HWE image detected, installing HWE packages"
else
    echo "Standard image detected, skipping HWE packages"
    exit 0
fi

# Asus/Surface for HWE
curl --retry 3 -Lo /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo \
    https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-$(rpm -E %fedora)/lukenukem-asus-linux-fedora-$(rpm -E %fedora).repo

curl --retry 3 -Lo /etc/yum.repos.d/linux-surface.repo \
        https://pkg.surfacelinux.com/fedora/linux-surface.repo

# Asus Firmware -- Investigate if everything has been upstreamed
# git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware
# cp -rf /tmp/asus-firmware/* /usr/lib/firmware/
# rm -rf /tmp/asus-firmware

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

dnf5 -y install \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"

dnf5 -y swap \
    libwacom-data libwacom-surface-data

dnf5 -y swap \
    libwacom libwacom-surface

tee /usr/lib/modules-load.d/ublue-surface.conf << EOF
# Only on AMD models
pinctrl_amd

# Surface Book 2
pinctrl_sunrisepoint

# For Surface Laptop 3/Surface Book 3
pinctrl_icelake

# For Surface Laptop 4/Surface Laptop Studio
pinctrl_tigerlake

# For Surface Pro 9/Surface Laptop 5
pinctrl_alderlake

# For Surface Pro 10/Surface Laptop 6
pinctrl_meteorlake

# Only on Intel models
intel_lpss
intel_lpss_pci

# Add modules necessary for Disk Encryption via keyboard
surface_aggregator
surface_aggregator_registry
surface_aggregator_hub
surface_hid_core
8250_dw

# Surface Laptop 3/Surface Book 3 and later
surface_hid
surface_kbd
EOF

echo "::endgroup::"
