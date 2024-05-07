#!/usr/bin/bash
#shellcheck disable=SC2154

if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi

# Common Build ISO
# shellcheck disable=SC1091
. "${project_root}/scripts/common-build-iso.sh"

# Make ISO
${container_mgr} run --rm --privileged  \
    --volume "${workspace}"/scripts/files/build-iso-makefile-patch:/build-container-intaller/container/Makefile \
    --volume "${workspace}":/build-container-installer/build  \
    ghcr.io/jasonn3/build-container-installer:latest \
    ARCH="x86_64" \
    ENABLE_CACHE_DNF="false" \
    ENABLE_CACHE_SKOPEO="false" \
    ENABLE_FLATPAK_DEPENDENCIES="false" \
    ENROLLMENT_PASSWORD="ublue-os" \
    FLATPAK_REMOTE_REFS_DIR="${flatpak_dir_shortname}" \
    IMAGE_NAME="${tag}" \
    IMAGE_REPO="localhost" \
    IMAGE_TAG="${version}" \
    ISO_NAME="${tag}-${version}.iso" \
    SECURE_BOOT_KEY_URL='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der' \
    VARIANT="${variant}" \
    VERSION="${version}"