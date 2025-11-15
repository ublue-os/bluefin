#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Download official Homebrew install script
echo "Downloading official Homebrew installer script..."
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
  -o /usr/share/ublue-os/homebrew-install.sh

# Make script executable
chmod +x /usr/share/ublue-os/homebrew-install.sh

# Verify the script was downloaded
if [ -f /usr/share/ublue-os/homebrew-install.sh ]; then
    echo "Homebrew installer downloaded successfully"
    ls -lh /usr/share/ublue-os/homebrew-install.sh
else
    echo "Error: Failed to download Homebrew installer"
    exit 1
fi

echo "::endgroup::"
