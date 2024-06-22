#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi
# shellcheck disable=SC1091
. "${project_root}/scripts/sudoif.sh"

set -euox pipefail

#shellcheck disable=SC2154
sudoif rm -f "${project_root}"/scripts/files/output/* #ISOs
rm -f "${project_root}"/*_flatapks/flatpaks_with_deps #Flatpak Deps
rm -rf "${project_root}"/flatpak.* #Flatpak Tempdir
sudoif rm -rf "${project_root}"/scripts/files/home/ublue-os/* #Test User Home
