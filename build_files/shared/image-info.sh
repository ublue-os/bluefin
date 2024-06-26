#!/usr/bin/env bash

set -ouex pipefail

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

case $FEDORA_MAJOR_VERSION in
  39)
    if [[ -n "${COREOS_TYPE:-}" ]]; then
      IMAGE_TAG="gts-coreos"
    else
      IMAGE_TAG="gts"
    fi
    ;;
  40)
    if [[ -n "${COREOS_TYPE:-}" ]]; then
      IMAGE_TAG="latest-coreos"
    else
      IMAGE_TAG="latest"
    fi
    ;;
  *)
    if [[ -n "${COREOS_TYPE:-}" ]]; then
      IMAGE_TAG="${FEDORA_MAJOR_VERSION}-coreos"
    else
      IMAGE_TAG="$FEDORA_MAJOR_VERSION"
    fi
    ;;
esac

if [[ "${COREOS_TYPE}" == "nvidia" ]]; then
  image_flavor="nvidia"
else
  image_flavor="${IMAGE_FLAVOR}"
fi

cat > $IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"$IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF

sed -i "s/VARIANT_ID.*/VARIANT_ID=$IMAGE_NAME/" /etc/os-release
