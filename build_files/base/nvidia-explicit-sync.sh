#!/usr/bin/bash

# Install Explicit Sync Patches on Nvidia builds
if [[ "${IMAGE_FLAVOR}" =~ "nvidia" && "${IMAGE_FLAVOR}" =~ "39" ]]; then
    wget https://copr.fedorainfracloud.org/coprs/gloriouseggroll/nvidia-explicit-sync/repo/fedora-$(rpm -E %fedora)/gloriouseggroll-nvidia-explicit-sync-fedora-$(rpm -E %fedora).repo?arch=x86_64 -O /etc/yum.repos.d/_copr_gloriouseggroll-nvidia-explicit-sync.repo
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:gloriouseggroll:nvidia-explicit-sync \
        xorg-x11-server-Xwayland
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:gloriouseggroll:nvidia-explicit-sync \
        egl-wayland \
        || true
    rm /etc/yum.repos.d/_copr_gloriouseggroll-nvidia-explicit-sync.repo
fi