#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf clean all

rm -rf /.gitkeep
find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

bootc container lint 

echo "::endgroup::"
