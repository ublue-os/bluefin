#!/usr/bin/bash
set -x

# Check if inside rootless container
if [[ -f /run/.containerenv ]]; then
    #shellcheck disable=SC1091
    source /run/.containerenv
    #shellcheck disable=SC2154
    if [[ "${rootless}" -eq "1" ]]; then
        echo "Cannot build ISO inside rootless podman container... Exiting..."
        exit 1
    fi
fi

container_mgr=$(just _container_mgr)
# If using rootless container manager, exit. Might not be best check
if "${container_mgr}" info | grep Root | grep -q /home; then
    echo "Cannot build ISO with rootless container..."
    exit 1
fi

# Inputs
image=$1
target=$2
version=$3

# Set image/target/version based off of inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get Base-Image and set container tag name
base_image=$(just _base_image "${image}")
tag=$(just _tag "${image}" "${target}")

# Don't use -build suffix, getting images from ghcr
tag=${tag::-6}

# Set variant and flatpak dir
if [[ "${base_image}" =~ "silverblue" ]]; then
    variant=Silverblue
    flatpak_dir_shortname="bluefin_flatpaks"
elif [[ "${base_image}" =~ "kinoite" ]]; then
    variant=Kinoite
    flatpak_dir_shortname="aurora_flatpaks"
else
    exit 1
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

workspace=${project_root}
if [[ -f /.dockerenv ]]; then
    FLATPAK_REFS_DIR=${LOCAL_WORKSPACE_FOLDER}/${flatpak_dir_shortname}
    TEMP_FLATPAK_INSTALL_DIR="${LOCAL_WORKSPACE_FOLDER}/$(echo "${TEMP_FLATPAK_INSTALL_DIR}" | rev | cut -d / -f 1 | rev)"
    workspace=${LOCAL_WORKSPACE_FOLDER}
fi

# Generate Flatpak Dependency List
"${container_mgr}" run --rm --privileged \
    --entrypoint bash \
    -e FLATPAK_SYSTEM_DIR=/flatpak/flatpak \
    -e FLATPAK_TRIGGERSDIR=/flatpak/triggers \
    --volume "${FLATPAK_REFS_DIR}":/output \
    --volume "${TEMP_FLATPAK_INSTALL_DIR}":/temp_flatpak_install_dir \
    "ghcr.io/ublue-os/${tag}:${version}" /temp_flatpak_install_dir/script.sh

# Remove Temp Directory
if [[ -f /.dockerenv ]]; then
    TEMP_FLATPAK_INSTALL_DIR=${project_root}/$(echo "${TEMP_FLATPAK_INSTALL_DIR}" | rev | cut -d / -f 1 | rev)
fi
rm -rf "${TEMP_FLATPAK_INSTALL_DIR}"

# Make ISO
${container_mgr} run --rm --privileged --volume "${workspace}":/build-container-installer/build  \
    ghcr.io/jasonn3/build-container-installer:latest \
    ARCH="x86_64" \
    ENABLE_CACHE_DNF="false" \
    ENABLE_CACHE_SKOPEO="false" \
    ENABLE_FLATPAK_DEPENDENCIES="false" \
    ENROLLMENT_PASSWORD="ublue-os" \
    FLATPAK_REMOTE_REFS_DIR="${flatpak_dir_shortname}" \
    IMAGE_NAME="${tag}" \
    IMAGE_REPO="ghcr.io/ublue-os" \
    IMAGE_TAG="${version}" \
    ISO_NAME="${tag}-${version}-ghcr.iso" \
    SECURE_BOOT_KEY_URL='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der' \
    VARIANT="${variant}" \
    VERSION="${version}"