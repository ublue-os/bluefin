#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Fetch Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/"${AKMODS_FLAVOR}"-kernel:"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/kernel-rpms
KERNEL_TARGZ=$(jq -r '.layers[].digest' </tmp/kernel-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/kernel-rpms/"$KERNEL_TARGZ" -C /
mv /tmp/rpms/* /tmp/kernel-rpms/

if [[ -z "$(grep kernel-devel <<<$(rpm -qa))" ]]; then
    rpm-ostree install /tmp/kernel-rpms/kernel-devel-*.rpm
fi

# Fetch AKMODS RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Install RPMS
rpm-ostree install /tmp/akmods/kmods/*kvmfr*.rpm

echo "::endgroup::"
