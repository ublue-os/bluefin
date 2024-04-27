#!/bin/sh

BLUEFIN_FETCH_LOGO="$(find /usr/share/ublue-os/bluefin-logos/symbols/ | shuf -n 1 )"

alias fastfetch='/usr/bin/fastfetch --logo ${BLUEFIN_FETCH_LOGO}  -c /usr/share/ublue-os/ublue-os.jsonc'