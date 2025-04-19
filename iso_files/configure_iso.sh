#!/usr/bin/env bash

set -x

dnf --enablerepo="terra" install -y readymade-nightly

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<< $IMAGE_INFO)"
IMAGE_FLAVOR="$(jq -c -r '."image-flavor"' <<< $IMAGE_INFO)"

OUTPUT_NAME="ghcr.io/ublue-os/bluefin"
if [ "$IMAGE_FLAVOR" != "main" ] ; then
  OUTPUT_NAME="${OUTPUT_NAME}-${IMAGE_FLAVOR}"
fi

tee /etc/readymade.toml <<EOF
[install]
allowed_installtypes = ["wholedisk", "custom"]
copy_mode = "bootc"
bootc_imgref = "containers-storage:$OUTPUT_NAME:$IMAGE_TAG"

[distro]
name = "Bluefin"

[[postinstall]]
module = "Script"
EOF

mkdir -p /usr/share/readymade/postinstall.d
tee /usr/share/readymade/postinstall.d/10-flatpaks.sh <<EOF
#!/usr/bin/bash
set -x
mkdir -p /ostree/deploy/default/var/lib
rsync -aWHA /run/host/var/lib/flatpak /ostree/deploy/default/var/lib
EOF
chmod +x /usr/share/readymade/postinstall.d/10-flatpaks.sh

systemctl disable brew-setup.service
systemctl --global disable podman-auto-update.timer
systemctl disable rpm-ostree.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl --global disable ublue-user-setup.service
systemctl disable check-sb-key.service
