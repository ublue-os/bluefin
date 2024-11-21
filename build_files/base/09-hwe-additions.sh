#!/usr/bin/bash

set -eoux pipefail

if [[ "${IMAGE_NAME}" =~ hwe ]]; then
    echo "HWE image detected, installing HWE packages"
else
    echo "Standard image detected, skipping HWE packages"
    exit 0
fi

# Asus/Surface for HWE
dnf5 -y -q copr enable lukenukem/asus-linux

dnf5 config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo

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

dnf5 -y install \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"

tee /usr/lib/modules-load.d/ublue-surface.conf << EOF
# Add modules necessary for Disk Encryption via keyboard
surface_aggregator
surface_aggregator_registry
surface_aggregator_hub
surface_hid_core
8250_dw

# Surface Laptop 3/Surface Book 3 and later
surface_hid
surface_kbd

# Only on AMD models
pinctrl_amd

# Only on Intel models
intel_lpss
intel_lpss_pci

# For Surface Laptop 3/Surface Book 3
pinctrl_icelake

# For Surface Laptop 4/Surface Laptop Studio
pinctrl_tigerlake
EOF

