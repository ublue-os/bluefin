#!/usr/bin/bash

set -ouex pipefail

# GitHub Monaspace
DOWNLOAD_URL=$(curl https://api.github.com/repos/githubnext/monaspace/releases/latest | jq -r '.assets[] | select(.name| test(".*.zip$")).browser_download_url')
curl -Lo /tmp/monaspace-font.zip "$DOWNLOAD_URL"

unzip -qo /tmp/monaspace-font.zip -d /tmp/monaspace-font
mkdir -p /usr/share/fonts/monaspace
mv /tmp/monaspace-font/monaspace-v*/fonts/variable/* /usr/share/fonts/monaspace/
rm -rf /tmp/monaspace-font*

fc-cache -f /usr/share/fonts/monaspace
