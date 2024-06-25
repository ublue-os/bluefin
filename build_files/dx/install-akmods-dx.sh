#!/usr/bin/bash

set -ouex pipefail

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*kvmfr*.rpm
fi
