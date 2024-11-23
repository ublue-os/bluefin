#!/usr/bin/bash

set -eoux pipefail

# Make Alternatives Directory
mkdir -p /var/lib/alternatives

# Copy Files to Container
cp -r /ctx/just /tmp/just
cp /ctx/packages.json /tmp/packages.json
cp /ctx/system_files/shared/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml
rsync -rvK /ctx/system_files/shared/ /
rsync -rvK /ctx/system_files/"${BASE_IMAGE_NAME}"/ /

# Generate image-info.json
/ctx/build_files/base/00-image-info.sh

# Build Fix - Fix known skew offenders
/ctx/build_files/base/01-build-fix.sh

# Get COPR Repos
/ctx/build_files/base/02-install-copr-repos.sh

# Install Kernel and Akmods
/ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
/ctx/build_files/base/04-packages.sh

# Install Overrides and Fetch Install
/ctx/build_files/base/05-override-install.sh

# Base Image Changes
/ctx/build_files/base/07-base-image-changes.sh

# Get Firmare for Framework
/ctx/build_files/base/08-firmware.sh

# Make HWE changes
/ctx/build_files/base/09-hwe-additions.sh

# Install Brew
/ctx/build_files/base/10-brew.sh


## late stage changes

# Make sure Bootc works
/ctx/build_files/base/16-bootc.sh

# Systemd and Remove Items
/ctx/build_files/base/17-cleanup.sh

# Run workarounds for lf (Likely not needed)
/ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
/ctx/build_files/base/19-initramfs.sh

# Clean Up
mv /var/lib/alternatives /staged-alternatives
/ctx/build_files/shared/clean-stage.sh
mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
mkdir -p /var/tmp && \
chmod -R 1777 /var/tmp
ostree container commit
