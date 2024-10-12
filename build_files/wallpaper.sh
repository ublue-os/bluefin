#!/usr/bin/bash

set -ouex pipefail

if test "$BASE_IMAGE_NAME" = "silverblue"; then
    DATE_MONTH=$(date +%B | tr '[:upper:]' '[:lower:]')

    WALLPAPER_GSCHEMA_OVERRIDE_FILE="/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
    sed -i "s|picture-uri='file:///usr/share/backgrounds/bluefin/bluefin-.*-dynamic.xml'|picture-uri='file:///usr/share/backgrounds/bluefin/bluefin-${DATE_MONTH}-dynamic.xml'|g" "${WALLPAPER_GSCHEMA_OVERRIDE_FILE}"
    sed -i "s|picture-uri-dark='file:///usr/share/backgrounds/bluefin/bluefin-.*-dynamic.xml'|picture-uri-dark='file:///usr/share/backgrounds/bluefin/bluefin-${DATE_MONTH}-dynamic.xml'|g" "${WALLPAPER_GSCHEMA_OVERRIDE_FILE}"
fi
