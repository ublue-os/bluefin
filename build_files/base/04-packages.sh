#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# All DNF-related operations should be done here whenever possible

# use negativo17 for 3rd party packages with higher priority than default
# mitigate upstream packaging bug: https://bugzilla.redhat.com/show_bug.cgi?id=2332429
# swap the incorrectly installed OpenCL-ICD-Loader for ocl-icd, the expected package
# TODO: remove me when F42 dropped, F43 is not affected
if [[ "$(rpm -E %fedora)" == "42" ]]; then
dnf5 -y swap --repo='fedora' \
    OpenCL-ICD-Loader ocl-icd
fi

if ! grep -q fedora-multimedia <(dnf5 repolist); then
    # Enable or Install Repofile
    dnf5 config-manager setopt fedora-multimedia.enabled=1 ||
        dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
fi
# Set higher priority
dnf5 config-manager setopt fedora-multimedia.priority=90

# use override to replace mesa and others with less crippled versions
OVERRIDES=(
    "intel-gmmlib"
    "intel-mediasdk"
    "intel-vpl-gpu-rt"
    "libheif"
    "libva"
    "libva-intel-media-driver"
    "mesa-dri-drivers"
    "mesa-filesystem"
    "mesa-libEGL"
    "mesa-libGL"
    "mesa-libgbm"
    "mesa-va-drivers"
    "mesa-vulkan-drivers"
)

dnf5 distro-sync --skip-unavailable -y --repo='fedora-multimedia' "${OVERRIDES[@]}"
dnf5 versionlock add "${OVERRIDES[@]}"

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
    adwaita-fonts-all
    alsa-firmware
    alsa-tools-firmware
    bcache-tools
    borgbackup
    containerd
    cryfs
    davfs2
    ddcutil
    evtest
    fastfetch
    firewall-config
    fish
    flatpak-spawn
    foo2zjs
    fuse-encfs
    gcc
    git-credential-libsecret
    glow
    gnome-tweaks
    google-noto-sans-cjk-fonts
    grub2-tools-extra
    gum
    gvfs-nfs
    htop
    ibus-mozc
    ibus-unikey
    ifuse
    igt-gpu-tools
    input-remapper
    intel-vaapi-driver
    iwd
    jetbrains-mono-fonts-all
    just
    krb5-workstation
    libcamera-gstreamer
    libcamera-tools
    libgda
    libgda-sqlite
    libimobiledevice-utils
    libratbag-ratbagd
    libsss_autofs
    libva-utils
    libxcrypt-compat
    lm_sensors
    lshw
    make
    mozc
    mtools
    nautilus-gsconnect
    net-tools
    ocl-icd
    oddjob-mkhomedir
    opendyslexic-fonts
    openrgb-udev-rules
    openssh-askpass
    pam-u2f
    pam_yubico
    pamu2fcfg
    pipewire-libs-extra
    powerstat
    powertop
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
    smartmontools
    solaar-udev
    squashfs-tools
    sssd-ad
    sssd-krb5
    symlinks
    tcpdump
    tmux
    traceroute
    usbip
    vim
    waypipe
    xdg-terminal-exec
    yubikey-manager 
    zenity
    zsh
)

if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    dnf install -y nvtop
fi

# Version-specific Fedora package additions
case "$FEDORA_MAJOR_VERSION" in
    42)
        FEDORA_PACKAGES+=(
            evolution-ews-core
            uld
        )
        ;;
    43)
        FEDORA_PACKAGES+=(
            evolution-ews-core
            gnupg2-scdaemon
        )
        ;;
esac

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf -y install "${FEDORA_PACKAGES[@]}"

dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

dnf -y install --enablerepo=fedora-multimedia \
    -x PackageKit* \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

# From che/nerd-fonts
copr_install_isolated "che/nerd-fonts" "nerd-fonts"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "uupd" \
    "oversteer-udev"

# Version-specific COPR packages
# case "$FEDORA_MAJOR_VERSION" in
#    42)
        # bazaar and uupd from ublue-os/packages
        # copr_install_isolated "ublue-os/packages" "bazaar" "uupd"
        # ;;
    # 43)
        # bazaar from ublue-os/packages
        # copr_install_isolated "ublue-os/packages" "bazaar"
        # ;;
# esac

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    default-fonts-cjk-sans
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    fedora-third-party
    firefox
    firefox-langpacks
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    google-noto-sans-cjk-vf-fonts
    podman-docker
    totem-video-thumbnailer
    yelp
)

# Version-specific package exclusions
case "$FEDORA_MAJOR_VERSION" in
    42)
        EXCLUDED_PACKAGES+=(gnome-software cosign)
        ;;
    43)
        EXCLUDED_PACKAGES+=(gnome-software cosign)
        ;;
esac

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# Fix for ID in fwupd
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd fwupd

# TODO: remove me on next flatpak release when preinstall landed in Fedora
if [[ "$(rpm -E %fedora)" -ge "42" ]]; then
  dnf -y copr enable ublue-os/flatpak-test
  dnf -y copr disable ublue-os/flatpak-test
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
  dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test install flatpak-debuginfo flatpak-libs-debuginfo flatpak-session-helper-debuginfo
fi

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "41" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    rpm-ostree override replace https://bodhi.fedoraproject.org/updates/FEDORA-2024-dd2e9fb225
#fi

echo "::endgroup::"
