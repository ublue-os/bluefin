#!/usr/bin/bash
set -eo pipefail

image=$1
target=$2
version=$3

# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

container_mgr=$(just _container_mgr)
tag=$(just _tag "${image}" "${target}")
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi
$container_mgr run -it --rm localhost/"${tag}":"${version}" /usr/bin/bash