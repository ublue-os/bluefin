#!/usr/bin/bash

set -ouex pipefail

if [[ "${IMAGE_FLAVOR}" =~ "nvidia" ]]; then
  rm /usr/etc/dracut.conf.d/nvidia.conf
  rm /usr/lib/modprobe.d/nvidia.conf
fi

rm -f /etc/yum.repos.d/tailscale.repo
rm -f /etc/yum.repos.d/charm.repo
rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
echo "Hidden=true" >> /usr/share/applications/fish.desktop
echo "Hidden=true" >> /usr/share/applications/htop.desktop
echo "Hidden=true" >> /usr/share/applications/nvtop.desktop
if [ "$BASE_IMAGE_NAME" = "silverblue" ]; then
    echo "Hidden=true" >> /usr/share/applications/gnome-system-monitor.desktop
fi
rm -f /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo
