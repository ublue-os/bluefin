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
SHORTCUTS_TO_TEST=(
        "org.gnome.desktop.wm.keybindings:show-desktop:['<Super>d']"
        "org.gnome.desktop.wm.keybindings:switch-applications:['<Super>Tab']"
        "org.gnome.desktop.wm.keybindings:switch-applications-backward:['<Shift><Super>Tab']"
        "org.gnome.desktop.wm.keybindings:switch-windows:['<Alt>Tab']"
        "org.gnome.desktop.wm.keybindings:switch-windows-backward:['<Shift><Alt>Tab']"
        "org.gnome.desktop.wm.keybindings:switch-input-source:['<Shift><Super>space']"
        "org.gnome.desktop.wm.keybindings:unmaximize:['<Super>Down']"
        "org.gnome.settings-daemon.plugins.media-keys:home:['<Super>e']"
        "org.gnome.shell.extensions.search-light:shortcut-search:['<Super>space']"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0:binding:<Control><Alt>t"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0:command:/usr/bin/ptyxis --new-window"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1:binding:<Control><Alt>Return"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1:command:/usr/bin/ptyxis --new-window"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2:binding:<Control><Shift>Escape"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2:command:flatpak run io.missioncenter.MissionCenter"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3:binding:<Control><Alt>BackSpace"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3:command:flatpak run com.jeffser.Alpaca"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4:binding:<Super>Print"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4:command:flatpak run be.alexandervanhee.gradia --screenshot"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5:binding:<Control><Alt>space"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5:command:flatpak run it.mijorus.smile"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6:binding:<Super>period"
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6:command:flatpak run it.mijorus.smile"
)

    for shortcut in "${SHORTCUTS_TO_TEST[@]}"; do
        IFS=':' read -r schema key expected <<< "$shortcut"
        actual=$(gsettings get "$schema" "$key" 2>/dev/null || echo "NOT_FOUND")
        
        if [[ "$actual" != "$expected" ]]; then
            echo "❌ Keyboard shortcut mismatch: $schema:$key"
            echo "   Expected: $expected"
            echo "   Got: $actual"
            ((failed++))
        else
            echo "✓ $schema:$key"
        fi
    done

    if [[ "$failed" -gt 0 ]]; then
        echo "Keyboard shortcuts validation failed"
        exit 1
    fi



echo "::endgroup::"
