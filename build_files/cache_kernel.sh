#!/usr/bin/bash

set -eoux pipefail

if [[ -n "${NVIDIA_TYPE:-}" ]]; then
    rpm-ostree override replace --experimental \
        /tmp/kernel-rpms/kernel-[0-9]*.rpm \
        /tmp/kernel-rpms/kernel-core-*.rpm \
        /tmp/kernel-rpms/kernel-modules-*.rpm
fi
