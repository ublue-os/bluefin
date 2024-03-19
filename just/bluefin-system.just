# vim: set ft=make :
########################
### bluefin-system.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run a one minute system benchmark
benchmark:
    echo 'Running a 1 minute benchmark ...'
    stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience
bluefin-cli:
    @/usr/libexec/enable-bluefin-cli.sh

# Configure Terminal Experience
[private]
configure-terminal:
    @/usr/libexec/configure-terminal.sh

# Toggle between Bluefin and the Developer Experience
devmode:
    #!/usr/bin/env bash
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "/var/ublue-os/image" <<< $CURRENT_IMAGE
    then
        echo ""
        echo "Before we can switch to the Bluefin Developer Experience"
        echo "the current system needs an update. Please run 'just update'"
        echo "and reboot your system when the update is finished."
        exit
    fi
    if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
    then
        CURRENT_STATE="enabled"
    else
        CURRENT_STATE="disabled"
    fi
    echo "Developer mode is currently ${CURRENT_STATE}"
    echo "Enable or Disable developer mode"
    OPTION=$(gum choose Enable Disable)
    if [ "$OPTION" = "Enable" ]
    then
        if [ "$CURRENT_STATE" = "enabled" ]
        then
            echo "You are already on a developer image"
        else
            echo "Rebasing to a developer image"
            NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin/bluefin-dx/")
            rpm-ostree rebase $NEW_IMAGE
        fi
    elif [ "$OPTION" = "Disable" ]
    then
        if [ "$CURRENT_STATE" = "enabled" ]
        then
            echo "Rebasing to a non developer image"
            NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin-dx/bluefin/")
            rpm-ostree rebase $NEW_IMAGE
        else
            echo "You are currently not on a developer image"
        fi
    fi

alias shell := configure-shell

# Switch to a different shell
configure-shell ACTION="":
    #!/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_SHELL="$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust shell <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'fish' to select fish"
      echo "  Use 'zsh' to select zsh"
      echo "  Use 'bash' to select bash"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}Shell configuration${normal}"
      echo "${USER}'s shell is currently ${CURRENT_SHELL}"
      OPTION=$(Choose "fish" "zsh" "bash")
    fi
    if [ -z "$OPTION" ]; then
      exit 0
    else
      sudo usermod $USER --shell /usr/bin/$OPTION 
      printf "${USER}'s shell is now %s.\n" "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"
    fi

alias gnome-extensions := get-gnome-extensions

# Install recommended GNOME extensions
get-gnome-extensions:
    pip install --upgrade gnome-extensions-cli
    gext install nightthemeswitcher@romainvigier.fr
    gext install pano@elhan.io
    gext install weatheroclock@CleoMenezesJr.github.io

alias gnome-vrr := toggle-gnome-vrr

# Enable or Disable Gnome-VRR
toggle-gnome-vrr:
    #!/usr/bin/env bash
    if gsettings get org.gnome.mutter experimental-features | grep -q "variable-refresh-rate"
    then
      CURRENT_STATE="Enabled"
    else
      CURRENT_STATE="Disabled"
    fi
    echo "Gnome-VRR is currently ${CURRENT_STATE}"
    echo "Enable or Disable Gnome-VRR"
    OPTION=$(gum choose Enable Disable)
    if [ "$OPTION" = "Enable" ]
    then
      echo "Enabling Gnome-VRR"
      gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate','scale-monitor-framebuffer']"
    elif [ "$OPTION" = "Disable" ]
    then
      echo "Disabling Gnome-VRR"
      gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
    fi
    echo "To apply the changes make sure you logout and restart your session"

# Ptyxis terminal transparency
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
      printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>{{ opacity }}" | bc -q) -eq 1 ]]; then
      raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
      uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
      for i in ${uuids}; do
        location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
        gsettings set "${location}" opacity "{{ opacity }}"; done
      printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
      printf "Value must be between 0 and 1: %s.\n" "{{ opacity }}"
    fi

# Configure docker,incus-admin,lxd,libvirt container manager permissions
dx-group:
    sudo usermod -aG docker $USER
    sudo usermod -aG incus-admin $USER
    sudo usermod -aG lxd $USER
    sudo usermod -aG libvirt $USER
    @echo "Logout to use docker, incus-admin, lxd, libvirt"
