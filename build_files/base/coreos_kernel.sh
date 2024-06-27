#!/usr/bin/bash

set -eoux pipefail

if [[ -n "${COREOS_TYPE:-}" ]]; then
    KERNEL_VERSION="${KERNEL}"
    KERNEL_MAJOR_MINOR_PATCH=$(echo "$KERNEL_VERSION" | cut -d '-' -f 1)
    KERNEL_RELEASE=$(echo "$KERNEL_VERSION" | cut -d '-' -f 2)
    rpm-ostree override replace --experimental \
        "https://kojipkgs.fedoraproject.org//packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org//packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org//packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org//packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org//packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-extra-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm"
fi
