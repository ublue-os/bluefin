#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

IMPORTANT_PACKAGES_DX=(
    code
    containerd.io
    docker-ce
    docker-compose-plugin
    flatpak-builder
    libvirt
    qemu
    rocm-runtime
)

# docker-buildx-plugin not available for F44
if [[ "${FEDORA_MAJOR_VERSION}" != "44" ]]; then
    IMPORTANT_PACKAGES_DX+=(docker-buildx-plugin)
fi

for package in "${IMPORTANT_PACKAGES_DX[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
done

IMPORTANT_UNITS=(
    docker.socket
    podman.socket
)

for unit in "${IMPORTANT_UNITS[@]}"; do
    if ! systemctl is-enabled "$unit" 2>/dev/null | grep -q "^enabled$"; then
        echo "${unit} is not enabled"
        exit 1
    fi
done

echo "::endgroup::"
