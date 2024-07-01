#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# prepare to install userspace tablet driver
# note: the user needs to manually enable the systemctl service according to https://opentabletdriver.net/Wiki/FAQ/Linux#autostart
wget https://github.com/OpenTabletDriver/OpenTabletDriver/releases/latest/download/OpenTabletDriver.rpm -O /tmp/opentabletdriver.rpm

rpm-ostree install \
  acpica-tools \
  kio-fuse \
  /tmp/opentabletdriver.rpm
