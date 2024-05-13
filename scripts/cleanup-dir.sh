#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi

set -euox pipefail

#shellcheck disable=SC2154
rm -f "${project_root}"/scripts/files/output/* #ISOs
rm -f "${project_root}"/*_flatapks/flatpaks_with_deps #Flatpak Deps
rm -rf "${project_root}"/flatpak.* #Flatpak Tempdir
rm -rf "${project_root}"/scripts/files/home/ublue-os/* #Test User Home
