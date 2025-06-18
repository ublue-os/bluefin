#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script dynamic-wallpaper user 1 || exit 0

set -euo pipefail

# Enable dynamic wallpaper service and timer
echo "Enabling dynamic wallpaper service and timer"
systemctl --user enable --now bluefin-dynamic-wallpaper.service
systemctl --user enable --now bluefin-dynamic-wallpaper.timer
