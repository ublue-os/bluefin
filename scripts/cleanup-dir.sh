#!/usr/bin/bash

set -euox pipefail

#shellcheck disable=SC2154
rm -f "${project_root}"/*.iso
rm -f "${project_root}"/*_flatapks/flatpaks_with_deps
rm -rf "${project_root}"/flatpak.*