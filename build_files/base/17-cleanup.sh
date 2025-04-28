#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Setup Systemd
systemctl enable rpm-ostree-countme.service
systemctl enable tailscaled.service
systemctl enable dconf-update.service
systemctl enable ublue-fix-hostname.service
systemctl --global enable ublue-flatpak-manager.service
systemctl enable ublue-system-setup.service
systemctl enable ublue-guest-user.service
systemctl enable brew-setup.service
systemctl enable brew-upgrade.timer
systemctl enable brew-update.timer
systemctl --global enable ublue-user-setup.service
systemctl --global enable podman-auto-update.timer
systemctl enable check-sb-key.service

# Updater
if systemctl cat -- uupd.timer &> /dev/null; then
    systemctl enable uupd.timer
else
    systemctl enable rpm-ostreed-automatic.timer
    systemctl enable flatpak-system-update.timer
    systemctl --global enable flatpak-user-update.timer
fi

# Hide Desktop Files. Hidden removes mime associations
for file in fish htop nvtop; do
    if [[ -f "/usr/share/applications/$file.desktop" ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/"$file".desktop
    fi
done


#Disable autostart behaviour
rm -f /etc/xdg/autostart/solaar.desktop

#Add the Flathub Flatpak remote and remove the Fedora Flatpak remote
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl disable flatpak-add-fedora-repos.service

# Disable all COPRs and RPM Fusion Repos
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/tailscale.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/charm.repo
dnf5 -y copr disable ublue-os/staging
dnf5 -y copr disable ublue-os/packages
dnf5 -y copr disable che/nerd-fonts
dnf5 -y copr disable phracek/PyCharm
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
for i in /etc/yum.repos.d/rpmfusion-*; do
    sed -i 's@enabled=1@enabled=0@g' "$i"
done

if [ -f /etc/yum.repos.d/fedora-coreos-pool.repo ]; then
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-coreos-pool.repo
fi

echo "::endgroup::"
