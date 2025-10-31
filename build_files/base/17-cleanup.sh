#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Prevent Distrobox containers from being updated via the background service
if [[ "$(rpm -E %fedora)" -eq "42" ]]; then
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
fi


# Setup Systemd
systemctl enable rpm-ostree-countme.service
systemctl enable tailscaled.service
systemctl enable dconf-update.service
systemctl enable ublue-guest-user.service
systemctl --global enable bazaar.service
systemctl enable brew-setup.service
systemctl enable brew-upgrade.timer
systemctl enable brew-update.timer
systemctl enable ublue-fix-hostname.service
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service
systemctl --global enable podman-auto-update.timer
systemctl enable check-sb-key.service
systemctl enable input-remapper.service
systemctl enable flatpak-nuke-fedora.service

# run flatpak preinstall once at startup
if [[ "$(rpm -E %fedora)" -ge "42" ]]; then
  systemctl enable flatpak-preinstall.service
fi

# Updater
systemctl enable uupd.timer

# Disable the old update timer
systemctl disable rpm-ostreed-automatic.timer
systemctl disable flatpak-system-update.timer

# Hide Desktop Files. Hidden removes mime associations
for file in fish htop nvtop; do
    if [[ -f "/usr/share/applications/$file.desktop" ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/"$file".desktop
    fi
done

#Add the Flathub Flatpak remote and remove the Fedora Flatpak remote
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl disable flatpak-add-fedora-repos.service

# NOTE: With isolated COPR installation, most repos are never enabled globally.
# We only need to clean up repos that were enabled during the build process.

# Disable third-party repos
for repo in negativo17-fedora-multimedia tailscale fedora-cisco-openh264; do
    if [[ -f "/etc/yum.repos.d/${repo}.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/${repo}.repo"
    fi
done

# Disable all COPR repos (should already be disabled by helpers, but ensure)
for i in /etc/yum.repos.d/_copr:*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
if [[ -f "/etc/yum.repos.d/_copr_ublue-os-akmods.repo" ]]; then
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
fi

# Disable RPM Fusion repos
for i in /etc/yum.repos.d/rpmfusion-*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# Disable fedora-coreos-pool if it exists
if [ -f /etc/yum.repos.d/fedora-coreos-pool.repo ]; then
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-coreos-pool.repo
fi

echo "::endgroup::"
