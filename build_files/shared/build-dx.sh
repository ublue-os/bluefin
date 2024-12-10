#!/usr/bin/bash

set -eoux pipefail

# Make Alternatives Directory
mkdir -p /var/lib/alternatives

# Copy Files to Image
cp /ctx/packages.json /tmp/packages.json
rsync -rvK /ctx/system_files/dx/ /

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

# Branding Changes
sed -i '/^PRETTY_NAME/s/Bluefin/Bluefin-dx/' /usr/lib/os-release

# Systemd and Disable Repos
/ctx/build_files/dx/09-cleanup-dx.sh

# Clean Up
mv /var/lib/alternatives /staged-alternatives
/ctx/build_files/shared/clean-stage.sh
mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
mkdir -p /var/tmp && \
chmod -R 1777 /var/tmp
ostree container commit
