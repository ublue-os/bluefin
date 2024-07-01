#!/usr/bin/bash
set -eo pipefail
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi 
if [[ -z ${git_branch} ]]; then
    git_branch=$(git branch --show-current)
fi

# Get Inputs
image=$1
target=$2
version=$3

# Set image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get Fedora Version and Kernel Info
if [[ "${version}" == "stable" ]]; then
    KERNEL_RELEASE=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')
    fedora_version=$(echo "$KERNEL_RELEASE" | grep -oP 'fc\K[0-9]+')
elif [[ ${version} == "gts" ]]; then
    coreos_kernel_release=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')
    major_minor_patch=$(echo "$coreos_kernel_release" | cut -d '-' -f 1)
    coreos_fedora_version=$(echo "$coreos_kernel_release" | grep -oP 'fc\K[0-9]+')
    KERNEL_RELEASE="${major_minor_patch}-200.fc$(("$coreos_fedora_version" - 1))"
else
    KERNEL_RELEASE=$(skopeo inspect docker://ghcr.io/ublue-os/silverblue-main:"${version}" | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')
fi

fedora_version=$(echo "$KERNEL_RELEASE" | grep -oP 'fc\K[0-9]+')

# Get info
container_mgr=$(just _container_mgr)
base_image=$(just _base_image "${image}")
tag=$(just _tag "${image}" "${target}")

akmods_flavor=main
if [[ "${version}" == "gts" || \
    "${version}" == "stable" ]]; then
    coreos_type="main"
    akmods_flavor=coreos
fi


# Build Command
command=( build -f Containerfile )
if [[ ${container_mgr} == "docker" && ${TERM} == "dumb" ]]; then
    command+=(--progress=plain)
fi
command+=( --build-arg="BASE_IMAGE_NAME=${base_image}" )
command+=( --build-arg="IMAGE_NAME=${tag}" )
command+=( --build-arg="IMAGE_FLAVOR=main" )
command+=( --build-arg="IMAGE_VENDOR=localhost" )
command+=( --build-arg="FEDORA_MAJOR_VERSION=${fedora_version}" )
command+=( --build-arg="AKMODS_FLAVOR=${akmods_flavor}" )
command+=( --build-arg="COREOS_TYPE=${coreos_type:-}" )
command+=( --build-arg="KERNEL=${KERNEL_RELEASE:-}" )
command+=( --build-arg="UBLUE_IMAGE_TAG=${version}" )
command+=( --build-arg="SOURCE_IMAGE=${base_image}-main" )
command+=( --tag localhost/"${tag}:${version}-${git_branch}" )
command+=( --target "${target}" )
command+=( "${project_root}" )

# Build Image
$container_mgr ${command[@]}
