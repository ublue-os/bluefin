  #!/bin/bash
    source /usr/lib/ujust/ujust.sh
    GRUB_STATE="$(sudo grub2-editenv list | grep "menu_auto_hide")"
    if [ "$GRUB_STATE" == "menu_auto_hide=2" && "menu_auto_hide=1" ]; then
        GRUB_STATE="${b}Hidden${n}"
    else
        GRUB_STATE="${b}Not Hidden${n}"
    fi
      echo "${bold}Grub menu configuration${normal}"
      echo "Grub menu is set to: $GRUB_STATE"
      OPTION=$(Choose "Hide Grub" "Unhide Grub" )
    if [[ "${OPTION,,}" =~ ^hide ]]; then
      sudo grub2-editenv - set menu_auto_hide=2 boot_success=1
    elif [[ "${OPTION,,}" =~ ^unhide ]]; then
      sudo grub2-editenv - set menu_auto_hide=0 boot_success=1
    fi