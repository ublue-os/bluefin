#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# We need to have the ublue-os signing keys on the image!
# Published images without these keys won't be able to pull ghcr.io/ublue-os/*
# and can therefore not update!
# https://github.com/ublue-os/main/blob/963609eaf01f7c2bb1a76821fe6d0ec269d2df25/build_files/install.sh#L56
# https://github.com/ublue-os/packages/tree/1f77c7e7faa9ebad120609a10d79e0412376c3b7/packages/ublue-os-signing/src

KEY1=$(jq -r '.transports.docker."ghcr.io/ublue-os"[0].keyPaths[0]' /etc/containers/policy.json)
BACKUP_KEY=$(jq -r '.transports.docker."ghcr.io/ublue-os"[0].keyPaths[1]' /etc/containers/policy.json)
KEY1_SHA256="af78ecfda6eb21c35195af3739341715e9cfc3f2f5911dd9c10b0670547bf6e8"
BACKUP_KEY_SHA256="b723467015ba562d40b4645c98c51c65d8254bb59444f6e9962debcfe2315da0"

echo "${KEY1_SHA256}  ${KEY1}" | sha256sum -c -
echo "${BACKUP_KEY_SHA256}  ${BACKUP_KEY}" | sha256sum -c -

for i in bin/ujust share/ublue-os/just/{00-entry.just,apps.just,default.just,system.just,update.just,} ; do
   stat /usr/$i
done

test -f /usr/share/ublue-os/homebrew/fonts.Brewfile

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
    fedora-logos
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

if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
  NV_PACKAGES=(
      libnvidia-container-tools
      kmod-nvidia
      nvidia-driver-cuda
)
  for package in "${NV_PACKAGES[@]}"; do
      rpm -q "${package}" >/dev/null || { echo "Missing NVIDIA package: ${package}... Exiting"; exit 1 ; }
  done
fi

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

echo "::endgroup::"
