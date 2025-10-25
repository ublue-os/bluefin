#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf clean all

rm -rf /.gitkeep
rm -rf /tmp/* || true
find /var -mindepth 1 -delete
find /boot -mindepth 1 -delete
mkdir -p /var /boot

# Make /usr/local writeable
ln -s /var/usrlocal /usr/local

mkdir -p /var/tmp &&
    chmod -R 1777 /var/tmp

bootc container lint 

echo "::endgroup::"
