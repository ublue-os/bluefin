#!/bin/bash
/usr/bin/check-sb-key > /dev/null

if [[ $? -eq 1 ]]; then
    USER_ID=$(/usr/bin/loginctl list-users --output=json | jq -r '.[] | .user')
    XDG_DIR=$(/usr/bin/loginctl show-user $USER_ID | grep RuntimePath | cut -c 13-)
    /usr/bin/sudo -u \
        $USER_ID DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_DIR/bus \
        notify-send "WARNING" \
        "This machine has secure boot turned on, but you haven't enrolled Universal Blue's keys. Failing to enroll these before rebooting may cause your system to fail to boot. Follow this link https://docs.projectbluefin.io/introduction#secure-boot for instructions on how to enroll the keys." \
        -i dialog-warning \
        -u critical \
        -a mokutil \
        --wait