#!/usr/bin/bash

# Check if inside podman container
if [[ -f /run/.containerenv ]]; then
    echo "Cannot build ISO inside rootless podman container... Exiting..."
    exit 1
fi

# If using rootless container manager, exit
container_mgr=$(just _container_mgr)
if "${container_mgr}" info | grep runRoot | grep -q /run/user; then
    echo "Cannot build ISO with rootless container..."
    exit 1
fi
if "${container_mgr}" info | grep graphRoot | grep -q /home/"${USER}"; then
    echo "Cannot build ISO with rootless container..."
    exit 1
fi

image=$1
target=$2
version=$3

# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

base_image=$(just _base_image "${image}")
tag=$(just _tag "${image}" "${target}")

if [[ "${base_image}" =~ "silverblue" ]]; then
    variant=Silverblue
    flatpak_dir_shortname="bluefin_flatpaks"
elif [[ "${base_image}" =~ "kinoite" ]]; then
    variant=Kinoite
    flatpak_dir_shortname="aurora_flatpaks"
else
    exit 1
fi

# Make sure image actually exists, build if it doesn't
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

# Make temp space
TEMP_FLATPAK_INSTALL_DIR=$(mktemp -d -p /tmp flatpak.XXX)
# Get list of refs from directory
FLATPAK_REFS_DIR=${project_root}/${flatpak_dir_shortname}
FLATPAK_REFS_DIR_LIST=$(tr '\n' ' ' < "${FLATPAK_REFS_DIR}/flatpaks")

# Generate install script
cat << EOF > "${TEMP_FLATPAK_INSTALL_DIR}/script.sh"
cat /temp_flatpak_install_dir/script.sh
mkdir -p /flatpak/flatpak /flatpak/triggers
mkdir /var/tmp || true
chmod -R 1777 /var/tmp
flatpak config --system --set languages "*"
flatpak remote-add --system flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y ${FLATPAK_REFS_DIR_LIST}
ostree refs --repo=\${FLATPAK_SYSTEM_DIR}/repo | grep '^deploy/' | grep -v 'org\.freedesktop\.Platform\.openh264' | sed 's/^deploy\///g' > /output/flatpaks_with_deps
EOF

# Generate Flatpak Dependency List
"${container_mgr}" run --rm --privileged \
    --entrypoint bash \
    -e FLATPAK_SYSTEM_DIR=/flatpak/flatpak \
    -e FLATPAK_TRIGGERSDIR=/flatpak/triggers \
    --volume "${FLATPAK_REFS_DIR}":/output \
    --volume "${TEMP_FLATPAK_INSTALL_DIR}":/temp_flatpak_install_dir \
    "localhost/${tag}:${version}" /temp_flatpak_install_dir/script.sh

rm -rf "${TEMP_FLATPAK_INSTALL_DIR}"

${container_mgr} run --rm --privileged --volume "${project_root}":/build-container-installer/build  \
    --volume "${project_root}"/scripts/build-iso-makefile-patch:/build-container-intaller/container/Makefile \
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