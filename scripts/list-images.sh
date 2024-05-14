#!/usr/bin/bash
set -euo pipefail
container_mgr=(
    docker
    podman
    podman-remote
)
for i in "${container_mgr[@]}"; do
    if [[ $(command -v "$i") ]]; then
        echo "Container Manager: ${i}"
        ${i} images --filter "reference=localhost/bluefin*-build" --filter "reference=localhost/aurora*-build"
        echo ""
    fi
done
