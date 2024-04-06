#!/usr/bin/bash

set -ouex pipefail

find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

cp /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml