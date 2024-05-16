#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi
if [[ -z ${git_branch} ]]; then
    git_branch=$(git branch --show-current)
fi
set -eo pipefail

# Get Inputs
image=$1
target=$2
version=$3

# Get image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get variables
container_mgr=$(just _container_mgr)
tag=$(just _tag "${image}" "${target}")

#check if ISO exists. Create if it doesn't
if [[ ! -f "${project_root}/scripts/files/output/${tag}-${version}-${git_branch}.iso" ]]; then
    just build-iso "$image" "$target" "$version"
fi

workspace=${project_root}
if [[ -f /.dockerenv ]]; then
    workspace=${LOCAL_WORKSPACE_FOLDER}
fi

${container_mgr} run --rm --cap-add NET_ADMIN \
    --publish 127.0.0.1:8006:8006 \
    --env "CPU_CORES=2" \
    --env "RAM_SIZE=4G" \
    --env "DISK_SIZE=64G" \
    --env "BOOT_MODE=uefi" \
    --device=/dev/kvm \
    --volume "${workspace}/scripts/files/output/${tag}-${version}-${git_branch}.iso":/boot.iso \
    docker.io/qemux/qemu-docker
