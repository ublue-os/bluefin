#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

shopt -s extglob

rm -rf /tmp/* || true
rm -rf /var/!(cache)
rm -rf /var/cache/!(rpm-ostree)

echo "::endgroup::"
