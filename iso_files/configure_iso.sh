#!/usr/bin/env bash

set -x

dnf --enablerepo="terra" install -y readymade

tee /etc/readymade.toml <<EOF
[install]
allowed_installtypes = ["wholedisk"]
copy_mode = "bootc"
bootc_imgref = "containers-storage:ghcr.io/ublue-os/bluefin:41"

[distro]
name = "Bluefin"

[[postinstall]]
module = "Script"
EOF

systemctl disable brew-setup.service
systemctl --global disable podman-auto-update.timer
systemctl disable rpm-ostree.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl --global disable ublue-user-setup.service
systemctl disable check-sb-key.service
