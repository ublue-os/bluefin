#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===Remove CLI Wrap==="

# there is no 'rpm-ostree cliwrap uninstall-from-root', but this is close enough. See:
# https://github.com/coreos/rpm-ostree/blob/6d2548ddb2bfa8f4e9bafe5c6e717cf9531d8001/rust/src/cliwrap.rs#L25-L32
if [ -d /usr/libexec/rpm-ostree/wrapped ]; then
    # binaries which could be created if they did not exist thus may not be in wrapped dir
    rm -f \
        /usr/bin/yum \
        /usr/bin/dnf \
        /usr/bin/kernel-install
    # binaries which were wrapped
    mv -f /usr/libexec/rpm-ostree/wrapped/* /usr/bin
    rm -fr /usr/libexec/rpm-ostree
fi

if [ "${FEDORA_MAJOR_VERSION}" -lt 41 ]; then
    rpm-ostree install --idempotent dnf5 dnf5-plugins
fi
echo "::endgroup::"

echo "::group:: Copy Files"

# Make Alternatives Directory
mkdir -p /var/lib/alternatives

# Copy Files to Container
cp -r /ctx/just /tmp/just
cp /ctx/packages.json /tmp/packages.json
rsync -rvK /ctx/system_files/shared/ /
rsync -rvK /ctx/system_files/"${BASE_IMAGE_NAME}"/ /
echo "::endgroup::"

# Generate image-info.json
/ctx/build_files/base/00-image-info.sh

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
echo "::group:: Cleanup"
mv /var/lib/alternatives /staged-alternatives
/ctx/build_files/shared/clean-stage.sh
mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives &&
    mkdir -p /var/tmp &&
    chmod -R 1777 /var/tmp
ostree container commit
echo "::endgroup::"
