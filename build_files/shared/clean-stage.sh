#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf clean all

systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

rm -rf /.gitkeep

# We can clean those up, they are "discarded" by bootc anyway
# https://bootc-dev.github.io/bootc/filesystem.html#filesystem
find /var -mindepth 1 -delete
find /boot -mindepth 1 -delete
find /tmp -mindepth 1 -delete
mkdir -p /var /boot /tmp

echo "::endgroup::"
