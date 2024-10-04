#!/usr/bin/bash

set -ouex pipefail

if test "$BASE_IMAGE_NAME" = "silverblue"; then
    DATE_MONTH=$(date +%B | tr '[:upper:]' '[:lower:]')
    DATE_MONTH_NUM=$(date +%m)
    SEASON=""
    case $DATE_MONTH_NUM in
        12|01|02)
            SEASON="winter"
            ;;
        03|04|05)
            SEASON="spring"
            ;;
        06|07|08)
            SEASON="summer"
            ;;
        09|10|11)
            SEASON="autumn"
            ;;
    esac

    sed -i "s|picture-uri='file:///usr/share/backgrounds/bluefin/bluefin-.*-dynamic.xml'|picture-uri='file:///usr/share/backgrounds/bluefin/bluefin-${SEASON}-dynamic.xml'|g" /etc/dconf/db/local.d/00-background
    sed -i "s|picture-uri-dark='file:///usr/share/backgrounds/bluefin/bluefin-.*-dynamic.xml'|picture-uri-dark='file:///usr/share/backgrounds/bluefin/bluefin-${SEASON}-dynamic.xml'|g" /etc/dconf/db/local.d/00-background
fi
