#!/usr/bin/bash

# SPDX-FileCopyrightText: 2023-2025 The Bluefin Project Contributors
#
# SPDX-License-Identifier: Apache-2.0

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf clean all

systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

rm -rf /.gitkeep
find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

bootc container lint

echo "::endgroup::"
