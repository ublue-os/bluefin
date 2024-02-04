#!/usr/bin/bash

# Enables bluefin-cli quadlet and start it if not started

if ! systemctl --quiet --user is-enabled bluefin-cli.target; then
    echo "Enabling Bluefin-CLI"
    systemctl --user enable --now bluefin-cli.target > /dev/null
    if ! systemctl --quiet --user is-active bluefin-cli.service; then
        echo "Starting Bluefin-CLI"
        systemctl --user restart bluefin-cli.service
    fi
fi