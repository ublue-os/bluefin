#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# NVIDIA Post-Install Finalization
###############################################################################
# 1. Regenerates the initramfs to include the NVIDIA kernel module.
# 2. Sets kernel boot arguments to blacklist nouveau and enable NVIDIA DRM KMS.
#
# Must run AFTER install-nvidia.sh (requires kmod-nvidia already installed).
###############################################################################

echo "::group:: Regenerate Initramfs for NVIDIA"

KERNEL_VERSION="$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)"
export DRACUT_NO_XATTR=1
/usr/bin/dracut \
    --no-hostonly \
    --kver "${KERNEL_VERSION}" \
    --reproducible \
    -v \
    --add ostree \
    -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

echo "::endgroup::"

echo "::group:: Set NVIDIA Kernel Boot Arguments"

mkdir -p /usr/lib/bootc/kargs.d
tee /usr/lib/bootc/kargs.d/00-nvidia.toml << 'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]
EOF

echo "::endgroup::"
