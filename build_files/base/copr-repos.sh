#!/usr/bin/bash

set -ouex pipefail

# Add Staging repo
curl -Lo /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Add Bling repo
curl -Lo /etc/yum.repos.d/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/bling/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo

# 39 gets VRR and Ptyxis
if [ "${FEDORA_MAJOR_VERSION}" -eq "39" ]; then
    curl -Lo /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo
    rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter mutter-common gnome-control-center gnome-control-center-filesystem
    rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gtk4 \
        vte291 \
        vte-profile \
        libadwaita
    rpm-ostree install ptyxis
fi

# 40 gets Ptyxis and patched Mutter
if [ "${FEDORA_MAJOR_VERSION}" -eq "40" ]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        vte291 \
        vte-profile
    rpm-ostree install ptyxis
    # This has been quite broken
    # if [[ "${BASE_IMAGE_NAME}" =~ "silverblue" ]]; then
    #     rpm-ostree override replace \
    #     --experimental \
    #     --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    #         mutter
    # fi
fi

# Add Nerd Fonts
curl -Lo /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo
