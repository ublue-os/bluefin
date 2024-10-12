#!/usr/bin/bash

set -ouex pipefail

if test "${BASE_IMAGE_NAME}" = "silverblue"; then
    DATE_MONTH=$(date +%B | tr '[:upper:]' '[:lower:]')

    WALLPAPER_URI="/usr/share/backgrounds/bluefin/bluefin-${DATE_MONTH}-dynamic.xml"
    WALLPAPER_GSCHEMA_OVERRIDE_FILE="/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"

    echo "Setting wallpaper URI to ${WALLPAPER_URI}"

    sed -i "s|picture-uri='DO_NOT_CHANGE'|picture-uri='file://${WALLPAPER_URI}'|g" "${WALLPAPER_GSCHEMA_OVERRIDE_FILE}"
    sed -i "s|picture-uri-dark='DO_NOT_CHANGE'|picture-uri-dark='file://${WALLPAPER_URI}'|g" "${WALLPAPER_GSCHEMA_OVERRIDE_FILE}"
fi
