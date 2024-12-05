#!/bin/sh

BLUEFIN_FETCH_LOGO="$(/usr/bin/find /usr/share/ublue-os/bluefin-logos/symbols/* | /usr/bin/shuf -n 1 )"

alias fastfetch='/usr/bin/fastfetch --logo ${BLUEFIN_FETCH_LOGO} --color $(/usr/libexec/ublue-bling-fastfetch) -c /usr/share/ublue-os/ublue-os.jsonc'
