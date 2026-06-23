#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# NVIDIA 580 LTS (Proprietary) Driver Orchestrator
###############################################################################
# Installs proprietary NVIDIA 580 kernel modules and userspace drivers from
# pre-built akmods-nvidia-lts RPMs (negativo17 fedora-nvidia-lts repository).
#
# The RPMs are mounted at /tmp/akmods-nv by Containerfile.nvidia using a
# kernel-exact tag (main-44-<KERNEL_VERSION>), guaranteeing that the akmod
# kernel version matches the base image kernel at build time.
#
# Driver 580.xxx is the last branch supporting Maxwell, Pascal, and Volta GPUs.
# Supported until ~June 2028 (negativo17 fedora-nvidia-lts maintenance plan).
###############################################################################

echo "::group:: Install NVIDIA 580 LTS Proprietary Drivers"

AKMODS_PATH=/tmp/akmods-nv

# IMAGE_NAME drives variant-specific package selection inside install-nvidia.sh
# (gnome-shell-extension-supergfxctl-gex is only installed for silverblue/GNOME)
VARIANT_IMAGE_NAME=silverblue

IMAGE_NAME="${VARIANT_IMAGE_NAME}" \
AKMODNV_PATH="${AKMODS_PATH}" \
MULTILIB=0 \
    bash /ctx/build_files/install-nvidia.sh

echo "::endgroup::"
