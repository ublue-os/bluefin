#!/bin/bash
source /usr/lib/ujust/ujust.sh
GRUB_STATE="$(sudo grub2-editenv list | grep "^menu_auto_hide=")"
if [[ "$GRUB_STATE" == "menu_auto_hide=1" ]]; then
    GRUB_STATE="${bold}Hidden${normal}"
elif [[ "$GRUB_STATE" == "menu_auto_hide=2" ]]; then
    GRUB_STATE="${bold}Always Hidden${normal}"
else
    GRUB_STATE="${bold}Unhidden${normal}"
fi
echo "${bold}Grub menu configuration${normal}"
echo "Grub menu is set to: $GRUB_STATE"
OPTION=$(Choose "Always Hide Grub" "Hide Grub" "Show Grub" "Cancel")
if [[ "${OPTION,,}" =~ ^always ]]; then
    sudo grub2-editenv - set menu_auto_hide=2
    GRUB_STATE="${bold}Always Hidden${normal}"
elif [[ "${OPTION,,}" =~ ^hide ]]; then
    sudo grub2-editenv - set menu_auto_hide=1
    GRUB_STATE="${bold}Hidden${normal}"
elif [[ "${OPTION,,}" =~ ^show ]]; then
    sudo grub2-editenv - set menu_auto_hide=0
    GRUB_STATE="${bold}Unhidden${normal}"
else
    echo "Not Changing Settings"
fi
echo "Grub menu is set to: $GRUB_STATE"
