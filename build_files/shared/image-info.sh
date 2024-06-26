#!/usr/bin/env bash

set -ouex pipefail

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

case $FEDORA_MAJOR_VERSION in
  39)
    IMAGE_TAG="gts"
    ;;
  40)
    IMAGE_TAG="latest"
    ;;
  *)
    IMAGE_TAG="$FEDORA_MAJOR_VERSION"
    ;;
esac

#shellcheck disable=SC2153
image_flavor="${IMAGE_FLAVOR}"
fedora_version="${FEDORA_MAJOR_VERSION}"

if [[ -n "${COREOS_TYPE:-}" ]]; then
  fedora_version="stable"
  IMAGE_TAG="stable"
fi

if [[ "${COREOS_TYPE}" == "nvidia" ]]; then
  image_flavor="nvidia"
fi

cat > $IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"$IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$fedora_version"
}
EOF

sed -i "s/VARIANT_ID.*/VARIANT_ID=$IMAGE_NAME/" /etc/os-release
