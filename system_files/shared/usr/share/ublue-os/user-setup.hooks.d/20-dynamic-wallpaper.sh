#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script dynamic-wallpaper user 1 || exit 0

set -xeuo pipefail

# Enable dynamic wallpaper timer (it will start the service as needed)
echo "Enabling dynamic wallpaper timer"
systemctl --user enable --now bluefin-dynamic-wallpaper.timer
