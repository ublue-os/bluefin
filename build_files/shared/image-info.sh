#!/usr/bin/env bash

set -ouex pipefail

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

#shellcheck disable=SC2153
image_flavor="${IMAGE_FLAVOR}"

if [[ "${COREOS_TYPE}" == "nvidia" ]]; then
  image_flavor="nvidia"
fi

cat > $IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"$UBLUE_IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF

sed -i "s/VARIANT_ID.*/VARIANT_ID=$IMAGE_NAME/" /etc/os-release
