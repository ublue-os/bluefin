#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script framework tool 1 || exit 0

set -x

CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"
BIOS_VERSION="$(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null)"

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"

# Install framework_tool and wallpapers for Framework laptops
if [[ ":Framework:" =~ :$VEN_ID: ]]; then
    TOOL_MARKER="/var/lib/ublue-os/framework-tool.installed"
    WALLPAPER_MARKER="/var/lib/ublue-os/framework-wallpapers.installed"

    # Check if Homebrew is available
    if command -v brew &> /dev/null; then
        if [[ ! -f "$TOOL_MARKER" ]]; then
            echo "Framework laptop detected, installing framework_tool"
            if brew install --cask ublue-os/tap/framework_tool; then
                mkdir -p /var/lib/ublue-os
                touch "$TOOL_MARKER"
                echo "framework_tool installed successfully"
            else
                echo "Warning: framework_tool installation failed, will retry on next run"
            fi
        else
            echo "framework_tool already installed, skipping"
        fi

        if [[ ! -f "$WALLPAPER_MARKER" ]]; then
            echo "Installing Framework wallpapers"
            if brew install --cask ublue-os/tap/framework-wallpapers; then
                mkdir -p /var/lib/ublue-os
                touch "$WALLPAPER_MARKER"
                echo "Framework wallpapers installed successfully"
            else
                echo "Warning: framework-wallpapers installation failed, will retry on next run"
            fi
        else
            echo "Framework wallpapers already installed, skipping"
        fi
    else
        echo "Warning: brew not found, skipping Framework software installation (will retry when brew is available)"
    fi
fi
