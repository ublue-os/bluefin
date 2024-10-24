#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" = "silverblue" ]]; then
    # Remove desktop entries
    if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
    fi
    if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
    fi

    # GNOME Terminal is replaced with Ptyxis in F41+
    if [[ "${FEDORA_MAJOR_VERSION}" -lt "41" ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.gnome.Terminal.desktop
    fi
    
    # Create symlinks from old to new wallpaper names for backwards compatibility
    ln -s "/usr/share/backgrounds/bluefin/01-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-winter-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/04-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-spring-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/08-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-summer-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/11-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-autumn-dynamic.xml"
    ln -s "/usr/share/backgrounds/xe_clouds.jxl" "/usr/share/backgrounds/xe_clouds.jpeg"
    ln -s "/usr/share/backgrounds/xe_foothills.jxl" "/usr/share/backgrounds/xe_foothills.jpeg"
    ln -s "/usr/share/backgrounds/xe_space_needle.jxl" "/usr/share/backgrounds/xe_space_needle.jpeg"
    ln -s "/usr/share/backgrounds/xe_sunset.jxl" "/usr/share/backgrounds/xe_sunset.jpeg"

    # Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
    mkdir -p /tmp/bluefin-schema-test
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \;
    cp /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override /tmp/bluefin-schema-test/
    echo "Running error test for bluefin gschema override. Aborting if failed."
    # We are omitting "--strict" from the schema validation since GNOME <47 do not contain the accent-color keys.
    # We should ideally refactor this to handle multiple GNOME version schemas better
    glib-compile-schemas /tmp/bluefin-schema-test
    echo "Compiling gschema to include bluefin setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null
fi
