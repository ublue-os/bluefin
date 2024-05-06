#!/usr/bin/bash
set -eo pipefail

# Get Inputs
image=$1
target=$2
version=$3

# Set image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get info
container_mgr=$(just _container_mgr)
base_image=$(just _base_image "${image}")
tag=$(just _tag "${image}" "${target}")

# Build Image
$container_mgr build -f Containerfile \
    --build-arg="AKMODS_FLAVOR=main" \
    --build-arg="BASE_IMAGE_NAME=${base_image}" \
    --build-arg="SOURCE_IMAGE=${base_image}-main" \
    --build-arg="FEDORA_MAJOR_VERSION=${version}" \
    --tag localhost/"${tag}":"${version}" \
    --target "${target}" \
    "${project_root}"