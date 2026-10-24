#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# We do not need anything here at all
rm -rf /usr/src
rm -rf /usr/share/doc
# Remove kernel-devel from rpmdb because all package files are removed from /usr/src
rpm --erase --nodeps kernel-devel

mkdir -p /usr/share/doc/bluefin
# Offline Bluefin documentation
ghcurl "https://github.com/ublue-os/bluefin-docs/releases/download/0.1/bluefin.pdf" --retry 3 -o /tmp/bluefin.pdf
install -Dm0644 -t /usr/share/doc/bluefin/ /tmp/bluefin.pdf

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# November wallpaper: common ships 11-bluefin.xml without its SVGs; remove once common ships them
# (along with the 11-bluefin.xml overrides in system_files/shared/usr/share)
ARTWORK_URL="https://raw.githubusercontent.com/projectbluefin/artwork/f784bbe296ca224b70058807b3c6cb180516ac84/wallpapers/11-bluefin"
ghcurl "${ARTWORK_URL}/11-bluefin-day.svg" --retry 3 -o /tmp/11-bluefin-day.svg
ghcurl "${ARTWORK_URL}/11-bluefin-night.svg" --retry 3 -o /tmp/11-bluefin-night.svg
echo "7833a5c6ff095998551f564704597e786849fd5f4367947b47968681b01c218a  /tmp/11-bluefin-day.svg" | sha256sum -c -
echo "deab0feafa53c1c215165e6513431d5832a81f9aefdea2372265e85b26512d51  /tmp/11-bluefin-night.svg" | sha256sum -c -
install -Dm0644 -t /usr/share/backgrounds/bluefin/ /tmp/11-bluefin-day.svg /tmp/11-bluefin-night.svg

# Required for bluefin faces to work without conflicting with a ton of packages
rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin

# Remove desktop entries
if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
fi
if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
fi

# Add Mutter experimental-features
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    sed -i "/experimental-features/ s/\]/, 'kms-modifiers'&/" /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override
    echo "Compiling gschema to include bluefin setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas
fi

echo "::endgroup::"
