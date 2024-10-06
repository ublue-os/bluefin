#!/usr/bin/bash

set -eoux pipefail

if [[ -n "${NVIDIA_TYPE:-}" ]]; then
    rpm-ostree override remove \
        kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

    rpm-ostree install \
        /tmp/kernel-rpms/kernel-[0-9]*.rpm \
        /tmp/kernel-rpms/kernel-core-*.rpm \
        /tmp/kernel-rpms/kernel-modules-*.rpm
fi
