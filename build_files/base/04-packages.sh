#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Load secure COPR helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# NOTE:
# Packages are split into FEDORA_PACKAGES and COPR_PACKAGES to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
# Fedora packages are installed first in bulk (safe).
# COPR packages are installed individually with isolated enablement.

# Base packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    adcli
    adw-gtk3-theme
    bash-color-prompt
    bcache-tools
    bootc
    borgbackup
    cryfs
    davfs2
    ddcutil
    evtest
    fastfetch
    firewall-config
    fish
    foo2zjs
    fuse-encfs
    gcc
    git-credential-libsecret
    glow
    gnome-shell-extension-appindicator
    gnome-shell-extension-blur-my-shell
    gnome-shell-extension-caffeine
    gnome-shell-extension-dash-to-dock
    gnome-tweaks
    gum
    hplip
    ibus-mozc
    igt-gpu-tools
    ifuse
    input-remapper
    iwd
    jetbrains-mono-fonts-all
    krb5-workstation
    libgda
    libgda-sqlite
    libimobiledevice
    libratbag-ratbagd
    libsss_autofs
    libxcrypt-compat
    lm_sensors
    make
    mesa-libGLU
    mozc
    oddjob-mkhomedir
    opendyslexic-fonts
    openssh-askpass
    powertop
    printer-driver-brlaser
    pulseaudio-utils
    python3-pip
    python3-pygit2
    rclone
    restic
    samba
    samba-dcerpc
    samba-ldb-ldap-modules
    samba-winbind-clients
    samba-winbind-modules
    setools-console
    sssd-ad
    sssd-krb5
    sssd-nfs-idmap
    tailscale
    tmux
    usbip
    usbmuxd
    waypipe
    wireguard-tools
    wl-clipboard
    xprop
    yaru-theme
    zenity
    zsh
)

# Version-specific Fedora package additions
case "$FEDORA_MAJOR_VERSION" in
    41)
        FEDORA_PACKAGES+=(
            epson-inkjet-printer-escpr
            epson-inkjet-printer-escpr2
            google-noto-fonts-all
            uld
        )
        ;;
    42)
        FEDORA_PACKAGES+=(
            evolution-ews-core
            google-noto-fonts-all
            uld
        )
        ;;
    43)
        FEDORA_PACKAGES+=(
            evolution-ews-core
        )
        ;;
esac

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Install COPR packages using isolated enablement (secure)
echo "Installing COPR packages with isolated repo enablement..."

# From che/nerd-fonts
copr_install_isolated "che/nerd-fonts" "nerd-fonts"

# From ublue-os/staging
copr_install_isolated "ublue-os/staging" \
    "gnome-shell-extension-gsconnect" \
    "gnome-shell-extension-logo-menu" \
    "gnome-shell-extension-search-light" \
    "gnome-shell-extension-tailscale-gnome-qs" \
    "nautilus-gsconnect"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "bluefin-backgrounds" \
    "bluefin-cli-logos" \
    "bluefin-faces" \
    "bluefin-fastfetch" \
    "bluefin-schemas" \
    "ublue-bling" \
    "ublue-brew" \
    "ublue-fastfetch" \
    "ublue-motd" \
    "ublue-polkit-rules" \
    "ublue-setup-services"

# Version-specific COPR packages
case "$FEDORA_MAJOR_VERSION" in
    42)
        # bazaar and uupd from ublue-os/packages
        copr_install_isolated "ublue-os/packages" "bazaar" "uupd"
        ;;
    43)
        # bazaar from ublue-os/packages
        copr_install_isolated "ublue-os/packages" "bazaar"
        ;;
esac

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    firefox
    firefox-langpacks
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    podman-docker
    yelp
)

# Version-specific package exclusions
case "$FEDORA_MAJOR_VERSION" in
    42)
        EXCLUDED_PACKAGES+=(gnome-software)
        ;;
    43)
        EXCLUDED_PACKAGES+=(fwupd gnome-software)
        ;;
esac

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

echo "::endgroup::"
