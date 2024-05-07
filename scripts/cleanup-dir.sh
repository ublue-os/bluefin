#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi

set -euox pipefail

#shellcheck disable=SC2154
rm -f "${project_root}"/*.iso
rm -f "${project_root}"/*_flatapks/flatpaks_with_deps
rm -rf "${project_root}"/flatpak.*
rm -rf "${project_root}"/scripts/files/home/ublue-os/*