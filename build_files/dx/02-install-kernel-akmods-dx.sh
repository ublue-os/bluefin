#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Load secure COPR helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# Install looking-glass-kvmfr COPR for kvmfr-kmod-common dependency
copr_install_isolated "hikariknight/looking-glass-kvmfr" "kvmfr-kmod-common"

# Fetch AKMODS & Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location

# TODO: Figure out why some akmods require kernel-devel
# dnf5 versionlock clear
#
# if [[ -z "$(grep kernel-devel <<<$(rpm -qa))" ]]; then
#     dnf5 -y install /tmp/kernel-rpms/kernel-devel-*.rpm
# fi
#
# dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-headers kernel-modules kernel-modules-core kernel-modules-extra

# Install akmods addons first (provides common packages like kvmfr-kmod-common)
# Use reinstall to force local RPM even if package exists in enabled repos
if [[ -d /tmp/akmods/ublue-os ]]; then
    dnf5 -y reinstall /tmp/akmods/ublue-os/*.rpm || dnf5 -y install /tmp/akmods/ublue-os/*.rpm || true
fi

# Install RPMS
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 -y install /tmp/akmods/kmods/*kvmfr*.rpm || true
else
    dnf5 -y install /tmp/akmods/kmods/*kvmfr*.rpm
fi

echo "::endgroup::"
