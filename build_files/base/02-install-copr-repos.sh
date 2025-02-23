#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add Switcheroo Repo
dnf5 -y copr enable sentry/switcheroo-control_discrete

# Add Nerd Fonts Repo
dnf5 -y copr enable che/nerd-fonts

echo "::endgroup::"
