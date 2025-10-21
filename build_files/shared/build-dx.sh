#!/usr/bin/bash

set -eou pipefail

mkdir -p /var/roothome

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/dx/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

echo "::endgroup::"

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
sysctl -p

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d && cat >>/etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF

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

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh

ostree container commit
echo "::endgroup::"
