#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"

# We need to remove this package here because lots of files we add from `projectbluefin/common` override the rpm files and they also go away when you do `dnf remove`
dnf remove -y ublue-os-luks ublue-os-just ublue-os-udev-rules ublue-os-signing ublue-os-update-services

# Conflicts with a ton of packages, has to be removed before we copy all the files as well
rpm --erase --nodeps fedora-logos

# Copy Files to Container
rsync -rvK /ctx/system_files/shared/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

echo "::endgroup::"

# Generate image-info.json
/ctx/build_files/base/00-image-info.sh

# Install Kernel and Akmods
/ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
/ctx/build_files/base/04-packages.sh

# Install Overrides and Fetch Install
/ctx/build_files/base/05-override-install.sh

# Build GNOME Extensions from Git Submodules
/ctx/build_files/shared/build-gnome-extensions.sh

# Get Firmare for Framework
/ctx/build_files/base/08-firmware.sh

## late stage changes

# Systemd and Remove Items
/ctx/build_files/base/17-cleanup.sh

# Run workarounds for lf (Likely not needed)
/ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
/ctx/build_files/base/19-initramfs.sh

if [ "${IMAGE_FLAVOR}" == "dx" ] ; then
  # Now we build DX!
  /ctx/build_files/shared/build-dx.sh
fi

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh

# Clean Up
echo "::group:: Cleanup"
/ctx/build_files/shared/clean-stage.sh

echo "::endgroup::"

# Simple Tests
/ctx/build_files/base/20-tests.sh
