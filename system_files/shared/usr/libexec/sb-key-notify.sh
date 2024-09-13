#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

WARNING_MSG="This machine has secure boot turned on, but you haven't enrolled Universal Blue's keys. Failing to enroll these before rebooting **may cause your system to fail to boot**. Follow this link https://docs.projectbluefin.io/introduction#secure-boot ~for instructions on how to enroll the keys."
KEY_WARN_FILE="/run/user-motd-sbkey-warn.md"
KEY_DER_FILE="/etc/pki/akmods/certs/akmods-ublue.der"

mokutil --sb-state | grep -q enabled
SB_ENABLED=$?

if [ $SB_ENABLED -ne 0 ]; then
    echo "Secure Boot disabled. Skipping..."
    exit 0
fi

if mokutil --test-key "$KEY_DER_FILE"; then 
    if loginctl --help | grep -q "json=MODE"; then
        JSON_ARG="--json=short"
    fi
    USER_ID=$(loginctl list-users --output=json "$JSON_ARG" | jq -r '.[] | .user')
    XDG_DIR=$(loginctl show-user "$USER_ID" | grep RuntimePath | cut -c 13-)
    sudo -u "$USER_ID" \
        "DISPLAY=:0" \
        "DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_DIR/bus" \
        notify-send \
        "WARNING" \
        "$(echo "$WARNING_MSG" | tr -d '*~')" \
        -i dialog-warning \
        -u critical \
        -a mokutil \
        --wait

    echo "**WARNING**: $WARNING_MSG" > $KEY_WARN_FILE
else
    [ -e $KEY_WARN_FILE ] && rm $KEY_WARN_FILE
fi
