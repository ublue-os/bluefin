#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Patched shells and Switcheroo Patch
if [[ "$(rpm -E %fedora)" -eq "40" ]]; then
    dnf5 -y copr enable sentry/switcheroo-control_discrete
    dnf5 -y copr disable sentry/switcheroo-control_discrete
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell gnome-shell
    dnf5 versionlock add gnome-shell
    dnf5 -y swap \
        --repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control switcheroo-control
    dnf5 versionlock add switcheroo-control
elif [[ "$(rpm -E %fedora)" -ge "41" ]]; then
    # Enable Terra repo (Extras does not exist on F40)
    # shellcheck disable=SC2016
    dnf5 -y swap \
        --repo="terra, terra-extras" \
        gnome-shell gnome-shell
    dnf5 versionlock add gnome-shell
    dnf5 -y swap \
        --repo="terra, terra-extras" \
        switcheroo-control switcheroo-control
    dnf5 versionlock add switcheroo-control
fi

# Fix for ID in fwupd
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd fwupd

# Offline Bluefin documentation
curl --retry 3 -Lo /tmp/bluefin.pdf https://github.com/ublue-os/bluefin-docs/releases/download/0.1/bluefin.pdf
install -Dm0644 -t /usr/share/doc/bluefin/ /tmp/bluefin.pdf

# Starship Shell Prompt
curl --retry 3 -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >>/etc/bashrc

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
# Use old bluefin background package for GTS
# FIXME: remove this once GTS updates to fc41
# if [ "$(rpm --eval "%{dist}")" == ".fc40" ]; then
#     dnf5 install -y "bluefin-backgrounds-0.1.7-1$(rpm -E "%{dist}")"
#     # Pin to february wallpaper instead
#     sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/02/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
# else
dnf5 install -y bluefin-backgrounds
sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
# fi
glib-compile-schemas /usr/share/glib-2.0/schemas

# Required for bluefin faces to work without conflicting with a ton of packages
rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin

dnf5 -y swap fedora-logos bluefin-logos

# Consolidate Just Files

find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter

echo "::endgroup::"
