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

# Add Terra
dnf5 -y install --nogpgcheck --repofrompath --skip-unavailable 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}
dnf5 config-manager setopt "terra*".enabled=0

echo "::endgroup::"
