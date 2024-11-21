#!/usr/bin/bash

set -eoux pipefail

#incus, lxc, lxd
if [[ "${FEDORA_MAJOR_VERSION}" -lt "42" ]]; then
    dnf5 -y -q copr enable ganto/lxc4
fi

dnf5 -y -q copr enable ganto/umoci
dnf5 -y -q copr enable ublue-os/staging
dnf5 -y -q copr enable karmab/kcli
dnf5 -y -q copr enable atim/ubuntu-fonts
dnf5 -y -q copr enable hikariknight/looking-glass-kvmfr
