#!/usr/bin/bash

###############################################################################
# NVIDIA Driver Low-Level Installer
###############################################################################
# Installs NVIDIA proprietary drivers from pre-built akmods RPMs.
#
# Based on ublue-os/main build_files/nvidia-install.sh with improvements:
#   - Kernel guard aborts with a clear error on version mismatch (defense-in-depth)
#   - kmod↔driver version cross-check after install
#   - KERNEL_VERSION env var passed from the Containerfile ARG (build-time known value)
#
# Environment variables (set by caller):
#   AKMODNV_PATH  — path to mounted akmods RPMs (default: /tmp/akmods-nv)
#   IMAGE_NAME    — base image name for variant package selection
#   MULTILIB      — "1" to install 32-bit packages (default: 0)
#   KERNEL_VERSION — expected kernel EVR+arch (e.g. 7.0.9-205.fc44.x86_64)
###############################################################################

set -eoux pipefail

: "${AKMODNV_PATH:=/tmp/akmods-nv}"
: "${MULTILIB:=0}"

FRELEASE="$(rpm -E %fedora)"

# Source nvidia-vars: provides KERNEL_VERSION (akmod), NVIDIA_AKMOD_VERSION, DIST_ARCH, KMOD_REPO
# shellcheck source=/dev/null
source "${AKMODNV_PATH}"/kmods/nvidia-vars

find "${AKMODNV_PATH}"/

# ── Kernel guard ───────────────────────────────────────────────────────────
# The Containerfile uses a kernel-exact akmods-nvidia-lts tag, making mismatches
# impossible by construction. This guard is defense-in-depth that catches any
# configuration drift (e.g., manual tag override, image-versions.yml misalignment).
BASE_KERNEL="$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)"
if [[ "${BASE_KERNEL}" != "${KERNEL_VERSION}" ]]; then
    echo "ERROR: Kernel version mismatch — akmod and base image are out of sync!"
    echo "  Base image kernel : ${BASE_KERNEL}"
    echo "  Akmods kernel     : ${KERNEL_VERSION}"
    echo ""
    echo "Fix: update image-versions.yml so that akmods-nvidia-lts uses the tag"
    echo "  main-44-${BASE_KERNEL}"
    echo "and set kernel: ${BASE_KERNEL} for the bluefin entry."
    exit 1
fi
# ──────────────────────────────────────────────────────────────────────────

if ! command -v dnf5 >/dev/null; then
    echo "Requires dnf5 — exiting"
    exit 1
fi

if dnf5 repolist --all | grep -q rpmfusion; then
    dnf5 config-manager setopt "rpmfusion*".enabled=0
fi
dnf5 config-manager setopt fedora-cisco-openh264.enabled=0

dnf5 install -y "${AKMODNV_PATH}"/ublue-os/ublue-os-nvidia-addons-*.rpm

# ublue-os-akmods-addons: provides the SecureBoot MOK enrollment key.
# Users must enroll it via: sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
dnf5 install -y /tmp/akmods-addons/ublue-os-akmods-addons-*.rpm

if [[ "$(rpm -E '%{_arch}')" == "x86_64" && "${MULTILIB}" == "1" ]]; then
    MULTILIB_PKGS=(
        mesa-dri-drivers.i686
        mesa-filesystem.i686
        mesa-libEGL.i686
        mesa-libGL.i686
        mesa-libgbm.i686
        mesa-vulkan-drivers.i686
    )
    dnf5 install -y "${MULTILIB_PKGS[@]}"
fi

dnf5 config-manager setopt "fedora-nvidia*".enabled=1 nvidia-container-toolkit.enabled=1

NEGATIVO17_MULT_PREV_ENABLED=N
if dnf5 repolist --enabled | grep -q "fedora-multimedia"; then
    NEGATIVO17_MULT_PREV_ENABLED=Y
    dnf5 config-manager setopt fedora-multimedia.enabled=0
fi

STAGING_ENABLED=false
if [[ -f /etc/yum.repos.d/_copr_ublue-os-staging.repo ]]; then
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    STAGING_ENABLED=true
elif [[ -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ublue-os:staging.repo" ]]; then
    sed -i 's@enabled=0@enabled=1@g' "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ublue-os:staging.repo"
    STAGING_ENABLED=true
elif curl --fail -Lo /etc/yum.repos.d/_copr_ublue-os-staging.repo \
        "https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${FRELEASE}/ublue-os-staging-fedora-${FRELEASE}.repo" 2>/dev/null; then
    STAGING_ENABLED=true
else
    echo "WARNING: Could not download ublue-os/staging COPR repo; variant packages skipped"
fi

if [[ "${IMAGE_NAME}" == "silverblue" && "${STAGING_ENABLED}" == "true" ]]; then
    VARIANT_PKGS=(
        gnome-shell-extension-supergfxctl-gex
        supergfxctl
    )
else
    VARIANT_PKGS=()
fi

NVIDIA_RPMS=(
    "${AKMODNV_PATH}"/nvidia/*."$(rpm -E '%{_arch}')".rpm
    "${AKMODNV_PATH}"/nvidia/*.noarch.rpm
    nvidia-container-toolkit
    egl-wayland
    libva-nvidia-driver
    "${VARIANT_PKGS[@]+"${VARIANT_PKGS[@]}"}"
    "${AKMODNV_PATH}"/kmods/kmod-nvidia-"${KERNEL_VERSION}"-"${NVIDIA_AKMOD_VERSION}"."${DIST_ARCH}".rpm
)

if [[ "$(rpm -E '%{_arch}')" == "x86_64" && "${MULTILIB}" == "1" ]]; then
    NVIDIA_RPMS+=(
        "${AKMODNV_PATH}"/nvidia/*.i686.rpm
    )
fi

dnf5 install -y "${NVIDIA_RPMS[@]}"

# ── kmod ↔ driver version guard ───────────────────────────────────────────
KMOD_VERSION="$(rpm -q --queryformat '%{VERSION}' kmod-nvidia)"
DRIVER_VERSION="$(rpm -q --queryformat '%{VERSION}' nvidia-driver)"
if [[ "${KMOD_VERSION}" != "${DRIVER_VERSION}" ]]; then
    echo "ERROR: kmod-nvidia (${KMOD_VERSION}) ≠ nvidia-driver (${DRIVER_VERSION})"
    exit 1
fi
# ──────────────────────────────────────────────────────────────────────────

dnf5 config-manager setopt "fedora-nvidia*".enabled=0 nvidia-container-toolkit.enabled=0

if [[ "${STAGING_ENABLED}" == "true" ]]; then
    if [[ -f /etc/yum.repos.d/_copr_ublue-os-staging.repo ]]; then
        sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    elif [[ -f "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ublue-os:staging.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ublue-os:staging.repo"
    fi
fi

if [[ "${NEGATIVO17_MULT_PREV_ENABLED}" = "Y" ]]; then
    dnf5 config-manager setopt fedora-multimedia.enabled=1
fi

systemctl enable ublue-nvctk-cdi.service
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp

# Force NVIDIA module load at boot (fixes black screen on NVIDIA desktops)
sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
# Pre-load intel/amd iGPU for hardware acceleration in Chromium-based browsers
sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf

rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
