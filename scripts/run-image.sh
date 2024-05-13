#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
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

# Check if requested image exist, if it doesn't build it
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

# Run image
"${container_mgr}" run -it --rm localhost/"${tag}":"${version}" /usr/bin/bash
