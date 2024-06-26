#!/usr/bin/bash

set -ouex pipefail

# Nvidia Configurations
if [[ "${IMAGE_FLAVOR}" =~ "nvidia" || "${COREOS_TYPE}" =~ "nvidia" ]]; then
    # Restore x11 for Nvidia Images
    if [[ "${BASE_IMAGE_NAME}" =~ "kinoite" && "${FEDORA_MAJOR_VERSION}" -gt "39" ]]; then
        rpm-ostree install plasma-workspace-x11
    fi
fi
