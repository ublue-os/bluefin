#!/usr/bin/bash

set -eoux pipefail

echo "::group:: $(basename "$0")"

shopt -s extglob

rm -rf /tmp/* || true
rm -rf /var/!(cache)
rm -rf /var/cache/!(rpm-ostree)

echo "::endgroup::"
