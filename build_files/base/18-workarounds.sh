#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "41" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    rpm-ostree override replace https://bodhi.fedoraproject.org/updates/FEDORA-2024-dd2e9fb225
#fi

# Current bluefin systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/bluefin-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/bluefin-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

echo "::endgroup::"
