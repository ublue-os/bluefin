#!/usr/bin/bash

set -ouex pipefail

# Add Staging repo
curl -Lo /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Add Bling repo
curl -Lo /etc/yum.repos.d/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/bling/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo

# 39 Ptyxis
if [ "${FEDORA_MAJOR_VERSION}" -eq "39" ]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gtk4 \
        vte291 \
        libadwaita \
        mutter \
        mutter-common \
        gnome-control-center \
        gnome-control-center-filesystem 
    rpm-ostree install ptyxis
fi

# Patched switcheroo
# Add repo
curl -Lo /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo https://copr.fedorainfracloud.org/coprs/sentry/switcheroo-control_discrete/repo/fedora-"${FEDORA_MAJOR_VERSION}"/sentry-switcheroo-control_discrete-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Patched shells
if [[ "${BASE_IMAGE_NAME}" = "silverblue" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell
elif [[ "${BASE_IMAGE_NAME}" = "kinoite" && "${FEDORA_MAJOR_VERSION}" -gt "39" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        kf6-kio-doc \
        kf6-kio-widgets-libs \
        kf6-kio-core-libs \
        kf6-kio-widgets \
        kf6-kio-file-widgets \
        kf6-kio-core \
        kf6-kio-gui
elif [[ "${BASE_IMAGE_NAME}" = "kinoite" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        kf5-kio-ntlm \
        kf5-kio-doc \
        kf5-kio-widgets-libs \
        kf5-kio-core-libs \
        kf5-kio-widgets \
        kf5-kio-file-widgets \
        kf5-kio-core \
        kf5-kio-gui
fi

# GNOME Triple Buffering
if [[ "${BASE_IMAGE_NAME}" = "silverblue" && "${FEDORA_MAJOR_VERSION}" -gt "39" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        mutter \
        mutter-common
fi

# Fix for ID in fwupd
if [[ "${FEDORA_MAJOR_VERSION}" -gt "39" ]]; then
    rpm-ostree override replace \
        --experimental \
        --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
            fwupd \
            fwupd-plugin-flashrom \
            fwupd-plugin-modem-manager \
            fwupd-plugin-uefi-capsule-data
fi

# Switcheroo patch
rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control

rm /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo

# Add Nerd Fonts
curl -Lo /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo
