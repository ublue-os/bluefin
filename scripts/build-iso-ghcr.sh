#!/usr/bin/bash
#shellcheck disable=SC2154

if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi

# Common Build ISO
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/common-build-iso.sh"

# Make ISO
${container_mgr} run --rm --privileged \
    --volume "${workspace}"/scripts/files/output:/build-container-installer/build  \
    --volume "${workspace}/${flatpak_dir_shortname}":"/build-container-installer/${flatpak_dir_shortname}" \
    ghcr.io/jasonn3/build-container-installer:latest \
    ARCH="x86_64" \
    ENABLE_CACHE_DNF="false" \
    ENABLE_CACHE_SKOPEO="false" \
    ENABLE_FLATPAK_DEPENDENCIES="false" \
    ENROLLMENT_PASSWORD="ublue-os" \
    FLATPAK_REMOTE_REFS_DIR="${flatpak_dir_shortname}" \
    IMAGE_NAME="${ghcr_tag}" \
    IMAGE_REPO="ghcr.io/ublue-os" \
    IMAGE_TAG="${version}" \
    ISO_NAME="build/${ghcr_tag}-${version}-ghcr.iso" \
    SECURE_BOOT_KEY_URL='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der' \
    VARIANT="${variant}" \
    VERSION="${fedora_version}"
