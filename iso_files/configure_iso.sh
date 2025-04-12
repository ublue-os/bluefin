#!/usr/bin/env bash

set -x

dnf --enablerepo="terra" install -y readymade

# TODO: Figure out exactly what needs to happen in this file
tee /etc/readymade.toml <<EOF
[install]
allowed_installtypes = ["wholedisk"]

[distro]
name = "Bluefin"

[[postinstall]]
module = "CleanupBoot"

[[postinstall]]
module = "InitialSetup"

[[postinstall]]
module = "Language"
EOF

systemctl disable brew-setup.service
systemctl --global disable podman-auto-update.timer
systemctl disable rpm-ostree.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl --global disable ublue-user-setup.service
systemctl disable check-sb-key.service
