#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

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

# Install RPMS
dnf5 -y install /tmp/akmods/kmods/*kvmfr*.rpm

echo "::endgroup::"
