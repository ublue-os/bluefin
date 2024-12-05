#!/usr/bin/fish
#shellcheck disable=all
function fastfetch
    set BLUEFIN_FETCH_LOGO (/usr/bin/find "/usr/share/ublue-os/bluefin-logos/symbols/" -mindepth 1 | /usr/bin/shuf -n 1)
    /usr/bin/fastfetch --logo $BLUEFIN_FETCH_LOGO --color (/usr/libexec/ublue-bling-fastfetch) -c "/usr/share/ublue-os/ublue-os.jsonc"
end
