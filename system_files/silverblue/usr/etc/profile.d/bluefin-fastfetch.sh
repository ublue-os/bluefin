#!/bin/sh

BLUEFIN_LOGO_PATH=/usr/share/ublue-os/bluefin-logos/symbols
BLUEFIN_LOGO_RANDOM=$(shuf -e "$(ls -1 ${BLUEFIN_LOGO_PATH})" | head -1)
BLUEFIN_FETCH_LOGO="${BLUEFIN_LOGO_PATH}/${BLUEFIN_LOGO_RANDOM}"

#shellcheck disable=SC2139
alias fastfetch="/usr/bin/fastfetch --logo ${BLUEFIN_FETCH_LOGO}  -c /usr/share/ublue-os/ublue-os.jsonc"