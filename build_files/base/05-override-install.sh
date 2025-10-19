#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Load secure repo helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# NOTE:
# This script uses isolated repo enablement for package swaps.
# The --repo= flag ensures only the specified repo can be used for that specific command.
# This prevents malicious repos from injecting fake versions of other packages.

# Install Terra repo (skip for Fedora 43+)
# Repo is installed but kept disabled for isolated enablement
# shellcheck disable=SC2016
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
    thirdparty_repo_install "terra" \
                           'terra,https://repos.fyralabs.com/terra$releasever' \
                           "terra-release" \
                           "terra-release-extras" \
                           "terra*"
fi

# Swap packages from Terra repo using isolated enablement (Extras does not exist on F40, not used for F43+)
# shellcheck disable=SC2016
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
    dnf5 -y swap \
        --repo=terra --repo=terra-extras \
        gnome-shell gnome-shell
    dnf5 versionlock add gnome-shell
    dnf5 -y swap \
        --repo=terra --repo=terra-extras \
        switcheroo-control switcheroo-control
    dnf5 versionlock add switcheroo-control
fi

# Fix for ID in fwupd
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
    dnf5 -y swap \
        --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        fwupd fwupd
fi

# TODO: remove me on next flatpak release when preinstall landed
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
  dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
  dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
  dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
  # print information about flatpak package, it should say from our copr
  rpm -q flatpak --qf "%{NAME} %{VENDOR}\n" | grep ublue-os
fi

# Offline Bluefin documentation
ghcurl "https://github.com/ublue-os/bluefin-docs/releases/download/0.1/bluefin.pdf" --retry 3 -o /tmp/bluefin.pdf
install -Dm0644 -t /usr/share/doc/bluefin/ /tmp/bluefin.pdf

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >>/etc/bashrc

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
glib-compile-schemas /usr/share/glib-2.0/schemas

# Required for bluefin faces to work without conflicting with a ton of packages
rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin

# Swap/install bluefin branding packages from ublue-os/packages COPR using isolated enablement
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
    fedora-logos bluefin-logos
dnf5 -y install \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
    bluefin-plymouth

# Consolidate Just Files

find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter

echo "::endgroup::"
