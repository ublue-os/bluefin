#!/usr/bin/bash

# Choose to enable or disable bluefin-cli

# shellcheck disable=1091
# shellcheck disable=2206
# shellcheck disable=2154
source /usr/lib/ujust/ujust.sh

bluefin_cli=(${red}Disabled${n} ${red}Inactive${n})

function get_status(){
    if systemctl --quiet --user is-enabled bluefin-cli.target; then
        bluefin_cli[0]="${green}Enabled${n}"
    else
        bluefin_cli[0]="${red}Disabled${n}"
    fi
    if systemctl --quiet --user is-active bluefin-cli.service; then
        bluefin_cli[1]="${green}Active${n}"
    else
        bluefin_cli[1]="${red}Inactive${n}"
    fi
    echo "Bluefin-cli is currently ${b}${bluefin_cli[0]}${n} and ${b}${bluefin_cli[1]}${n}"
}
function logic(){
    if test "$toggle" = "Enable"; then
        echo "${b}${green}Enabling${n} Bluefin-CLI"
        systemctl --user enable --now bluefin-cli.target > /dev/null 2>&1 
        if ! systemctl --quiet --user is-active bluefin-cli.service; then
            systemctl --user reset-failed bluefin-cli.service > /dev/null 2>&1 || true
            echo "${b}${green}Starting${n} Bluefin-CLI"
            systemctl --user start bluefin-cli.service
        fi
    elif test "$toggle" = "Disable"; then
        echo "${b}${red}Disabling${n} Bluefin-CLI"
        systemctl --user disable --now bluefin-cli.target > /dev/null 2>&1
        if systemctl --quiet --user is-active bluefin-cli.service; then
            echo "Do you want to ${b}${red}Stop${n} the Container?"
            stop=$(Confirm)
            if test "$stop" -eq 0; then
                systemctl --user stop bluefin-cli.service > /dev/null 2>&1
                systemctl --user reset-failed bluefin-cli.service > /dev/null 2>&1 || true
            fi
        fi
    else
        echo "Not Changing"
    fi
}

function main(){
    get_status
    toggle=$(Choose Enable Disable Cancel)
    logic
    get_status
}

main