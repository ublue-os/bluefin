#!/usr/bin/bash

# Choose to enable or disable bluefin-cli

# shellcheck disable=1091
# shellcheck disable=2206
# shellcheck disable=2154
source /usr/lib/ujust/ujust.sh

bluefin_cli=(${red}Disabled${n} ${red}Inactive${n} ${red}Not Default${n})

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
    get_default=$(dconf read /org/gnome/Ptyxis/default-profile-uuid)
    if test "$get_default" = "'a21a910811504857bea4c96b3d937b93'"; then
        bluefin_cli[2]="${green}Default${n}"
    else
        bluefin_cli[2]="${red}Not-Default${n}"
    fi
    echo "Bluefin-cli is currently ${b}${bluefin_cli[0]}${n} (run status), ${b}${bluefin_cli[1]}${n} (on boot status), and ${b}${bluefin_cli[2]}${n} (terminal profile)."
}

function default_login(){
    toggle=$(Choose Default Not-Default Cancel)
    if test "$toggle" = "Default"; then
        echo "Setting Bluefin-CLI to default Ptyxis Profile"
        /usr/libexec/ptyxis-create-profile.sh bluefin-cli default
    elif test "$toggle" = "Not-Default"; then
        echo "Setting Host back to default Ptyxis Profile"
        /usr/libexec/ptyxis-create-profile.sh Host default
    else
        dconf write /or
        echo "Not Changing"
    fi
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
        default_login
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
        echo "Setting Host back to default Ptyxis Profile"
        /usr/libexec/ptyxis-create-profile.sh Host default
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
