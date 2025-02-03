#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Patched shells
dnf5 -y swap \
--repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    gnome-shell gnome-shell

# GNOME Triple Buffering
if [[ "${BASE_IMAGE_NAME}" =~ silverblue && "${FEDORA_MAJOR_VERSION}" -lt "41" ]]; then
    dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        mutter mutter
fi

# Fix for ID in fwupd
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        fwupd fwupd

# Switcheroo patch
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control switcheroo-control

dnf5 -y copr remove sentry/switcheroo-control_discrete

# Starship Shell Prompt
curl --retry 3 -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Topgrade Install
pip install --prefix=/usr topgrade

# Install ublue-update -- breaks with packages.json due to missing topgrade
dnf5 -y install ublue-update

# Required for bluefin faces to work without conflicting with a ton of packages
rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
glib-compile-schemas /usr/share/glib-2.0/schemas

dnf5 -y swap fedora-logos bluefin-logos

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Move over ublue-update config
mv -f /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter

echo "::endgroup::"
