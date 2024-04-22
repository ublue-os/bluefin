#!/usr/bin/bash

set -ouex pipefail

rm -f /etc/yum.repos.d/tailscale.repo
rm -f /etc/yum.repos.d/charm.repo
rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/fish.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop
if [[ "$BASE_IMAGE_NAME" = "silverblue" && -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
fi
if [[ "$FEDORA_MAJOR_VERSION " -eq "38" ]]; then
    if [[ "$BASE_IMAGE_NAME" == "silverblue" ]]; then
        rm -f /usr/etc/profile.d/bluefin-fashfetch.sh
    elif [[ "$BASE_IMAGE_NAME" == "kinoite" ]]; then
        rm -f /usr/etc/profile.d/aurora-fastfetch.sh
    fi
fi
rm -f /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo
