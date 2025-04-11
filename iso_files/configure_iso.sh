#!/usr/bin/env bash

set -x

dnf install --nogpgcheck --repofrompath 'um,https://repos.fyralabs.com/um$releasever' readymade

tee /etc/readymade.toml <<EOF

EOF


systemctl disable brew-setup.service
systemctl --global disable podman-auto-update.timer
systemctl disable rpm-ostree.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl --global disable ublue-user-setup.service
systemctl disable check-sb-key.service
