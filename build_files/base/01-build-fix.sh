#!/usr/bin/bash

set -eoux pipefail

# This script provides fixes to packages known to have caused build skew.
# It works by force replacing packages on the FROM image with current
# packages from fedora update repos.

repos=(
    fedora-updates.repo
    fedora-updates-archive.repo
)

for repo in "${repos[@]}"; do
    if [[ "$(grep -c "enabled=1" /etc/yum.repos.d/"${repo}")" -eq 0 ]]; then
        sed -i "0,/enabled=0/{s/enabled=0/enabled=1/}" /etc/yum.repos.d/"${repo}"
    fi
done

rpm-ostree override replace \
    --experimental \
    --from repo=updates \
    elfutils-libelf \
    elfutils-libs ||
    true
