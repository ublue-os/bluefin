#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# If this file is not on the image bazaar will automatically be removed from users systems :(
# See: https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall
test -f /usr/share/flatpak/preinstall.d/bazaar.preinstall

# Basic smoke test to check if the flatpak version is from our copr
flatpak preinstall --help

# Make sure this garbage never makes it to an image
test -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service && false

IMPORTANT_PACKAGES=(
    distrobox
    fish
    flatpak
    mutter
    pipewire
    gnome-shell
    ptyxis
    gdm
    systemd
    tailscale
    uupd
    wireplumber
    zsh
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
done

# these packages are supposed to be removed
# and are considered footguns
UNWANTED_PACKAGES=(
    firefox
    gnome-software
    gnome-software-rpm-ostree
    podman-docker
)

for package in "${UNWANTED_PACKAGES[@]}"; do
    if rpm -q "${package}" >/dev/null 2>&1; then
        echo "Unwanted package found: ${package}... Exiting"; exit 1
    fi
done

# TODO: Enable when libnvidia-container-tools are on F43
#if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
#  NV_PACKAGES=(
#      libnvidia-container-tools
#      kmod-nvidia
#      nvidia-driver-cuda
#)
#  for package in "${NV_PACKAGES[@]}"; do
#      rpm -q "${package}" >/dev/null || { echo "Missing NVIDIA package: ${package}... Exiting"; exit 1 ; }
#  done
#fi

IMPORTANT_UNITS=(
    brew-update.timer
    brew-upgrade.timer
    rpm-ostree-countme.timer
    tailscaled.service
    ublue-system-setup.service
    uupd.timer
  )

for unit in "${IMPORTANT_UNITS[@]}"; do
    if ! systemctl is-enabled "$unit" 2>/dev/null | grep -q "^enabled$"; then
        echo "${unit} is not enabled"
        exit 1
    fi
done

# Test Homebrew installation files
echo "Testing Homebrew installation files..."

# Test that the homebrew installer script exists and is executable
test -f /usr/share/ublue-os/homebrew-install.sh || { echo "Missing homebrew installer script"; exit 1; }
test -x /usr/share/ublue-os/homebrew-install.sh || { echo "Homebrew installer script is not executable"; exit 1; }

# Test that all systemd service files exist
HOMEBREW_SYSTEMD_FILES=(
    /usr/lib/systemd/system/brew-setup.service
    /usr/lib/systemd/system/brew-update.service
    /usr/lib/systemd/system/brew-update.timer
    /usr/lib/systemd/system/brew-upgrade.service
    /usr/lib/systemd/system/brew-upgrade.timer
    /usr/lib/systemd/system-preset/01-homebrew.preset
)

for file in "${HOMEBREW_SYSTEMD_FILES[@]}"; do
    test -f "$file" || { echo "Missing systemd file: ${file}"; exit 1; }
done

# Test that shell integration files exist
HOMEBREW_SHELL_FILES=(
    /etc/profile.d/brew.sh
    /etc/profile.d/brew-bash-completion.sh
    /usr/share/fish/vendor_conf.d/ublue-brew.fish
)

for file in "${HOMEBREW_SHELL_FILES[@]}"; do
    test -f "$file" || { echo "Missing shell integration file: ${file}"; exit 1; }
done

# Test that system configuration files exist
test -f /usr/lib/tmpfiles.d/homebrew.conf || { echo "Missing tmpfiles.d/homebrew.conf"; exit 1; }
test -f /etc/security/limits.d/30-brew-limits.conf || { echo "Missing limits.d/30-brew-limits.conf"; exit 1; }

echo "All Homebrew installation files present and valid"

echo "::endgroup::"
