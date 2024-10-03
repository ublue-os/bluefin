#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" = "silverblue" ]]; then
    if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
    fi
    if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
    fi
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.gnome.Terminal.desktop
    # Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
    mkdir -p /tmp/bluefin-schema-test
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \;
    cp /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override /tmp/bluefin-schema-test/
    echo "Running error test for bluefin gschema override. Aborting if failed."
    glib-compile-schemas --strict /tmp/bluefin-schema-test
    echo "Compiling gschema to include bluefin setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null
fi
