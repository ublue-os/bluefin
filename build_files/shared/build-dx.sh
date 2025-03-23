#!/usr/bin/bash

set -eou pipefail

mkdir -p /var/roothome

echo "::group:: Copy Files"

# Copy Files to Image
cp /ctx/packages.json /tmp/packages.json
rsync -rvK /ctx/system_files/dx/ /
echo "::endgroup::"

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
sysctl -p

# Generate image-info.json (Not Needed?)
# /ctx/build_files/shared/image-info.sh

# COPR Repos
/ctx/build_files/dx/01-install-copr-repos-dx.sh

# Install AKMODS
/ctx/build_files/dx/02-install-kernel-akmods-dx.sh

# Install Packages
/ctx/build_files/dx/03-packages-dx.sh

# Fetch Install
/ctx/build_files/dx/04-override-install-dx.sh

# Systemd and Disable Repos
/ctx/build_files/dx/09-cleanup-dx.sh

# Clean Up
echo "::group:: Cleanup"
/ctx/build_files/shared/clean-stage.sh
mkdir -p /var/tmp &&
    chmod -R 1777 /var/tmp
ostree container commit
echo "::endgroup::"
