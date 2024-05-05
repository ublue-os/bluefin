#!/usr/bin/bash
set -eo pipefail

image=$1
target=$2
version=$3

# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

container_mgr=$(just _container_mgr)
base_image=$(just _base_image "${image}")
tag=$(just _tag "${image}" "${target}")
$container_mgr build -f Containerfile \
    --build-arg="AKMODS_FLAVOR=main" \
    --build-arg="BASE_IMAGE_NAME=${base_image}" \
    --build-arg="SOURCE_IMAGE=${base_image}-main" \
    --build-arg="FEDORA_MAJOR_VERSION=${version}" \
    --tag localhost/"${tag}":"${version}" \
    --target "${target}" \
    "${project_root}"