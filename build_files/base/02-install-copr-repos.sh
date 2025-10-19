#!/usr/bin/bash
# shellcheck disable=SC2016

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add Nerd Fonts Repo
dnf5 -y copr enable che/nerd-fonts

# Add Terra (skip for Fedora 43+)
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
    dnf5 -y install terra-release-extras || true
    dnf5 config-manager setopt "terra*".enabled=0
fi

# TODO: remove me on next flatpak release
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
  dnf5 -y copr enable ublue-os/flatpak-test
fi

echo "::endgroup::"
