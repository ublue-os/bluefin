#!/usr/bin/bash

# SPDX-FileCopyrightText: 2023-2025 The Bluefin Project Contributors
#
# SPDX-License-Identifier: Apache-2.0

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Current bluefin systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/bluefin-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/bluefin-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

echo "::endgroup::"
