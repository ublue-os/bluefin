#!/usr/bin/env bash

set -x

dnf --enablerepo="terra" install -y readymade

echo $ISO_MATRIX_VERSION
echo $ISO_MATRIX_FLAVOR

OUTPUT_NAME="ghcr.io/ublue-os/bluefin"
if [ "${ISO_MATRIX_FLAVOR}" != "" ] ; then
  OUTPUT_NAME="${OUTPUT_NAME}-${FLAVOR}"
fi

tee /etc/readymade.toml <<EOF
[install]
allowed_installtypes = ["wholedisk"]
copy_mode = "bootc"
bootc_imgref = "containers-storage:$OUTPUT_NAME:$ISO_IMAGE_VERSION"

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
