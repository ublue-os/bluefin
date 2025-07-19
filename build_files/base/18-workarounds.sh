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

# Use dnf list --showduplicates package

# Workaround atheros-firmware regression
# see https://bugzilla.redhat.com/show_bug.cgi?id=2365882
dnf -y swap atheros-firmware atheros-firmware-20250311-1$(rpm -E %{dist})


# Only downgrade for F42
if [ "$FEDORA_MAJOR_VERSION" -eq "42" ]; then
# Downgrade libdex to 0.9.1 because 0.10 makes bazaar crash under VMs and PCs with low specs
dnf5 install -y libdex-0.9.1
fi

# Current bluefin systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/bluefin-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/bluefin-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

# Workaround for Bazaar on NVIDIA systems
if [[ -f /usr/share/applications/io.github.kolunmi.Bazaar.desktop ]] && jq -e '.["image-flavor"] | test("nvidia")' /usr/share/ublue-os/image-info.json >/dev/null; then
  sed -i 's|^Exec=bazaar window --auto-service$|Exec=env GSK_RENDERER=opengl bazaar window --auto-service|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop
fi

echo "::endgroup::"
