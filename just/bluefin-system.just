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
[group('System')]
benchmark:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if ! type -P "stress-ng" &>/dev/null ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo 'Running a 1 minute benchmark ...'
    trap popd EXIT
    pushd $(mktemp -d)
    stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience with Brew
[group('System')]
bluefin-cli:
    @/usr/libexec/ublue-bling

# alias for toggle-devmode
devmode:
    @ujust toggle-devmode

# Toggle between Bluefin and the Developer Experience
[group('System')]
toggle-devmode:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "/var/ublue-os/image" <<< $CURRENT_IMAGE ; then
        bash -c "cat <<EOF
    Before we can switch to the Bluefin Developer Experience
    the current system needs an update. Please run 'ujust update'
    and reboot your system when the update is finished
    EOF"
        exit
    fi
    if /bin/grep -q "\-dx" <<< $CURRENT_IMAGE ; then
        CURRENT_STATE="enabled"
    else
        CURRENT_STATE="disabled"
    fi
    echo "Developer mode is currently ${CURRENT_STATE}"
    echo "Enable or Disable developer mode"
    OPTION=$(Choose Enable Disable)
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        if [ "$CURRENT_STATE" = "enabled" ] ; then
            echo "You are already on a developer image"
            exit 0
        fi
        echo "Rebasing to a developer image"
        NEW_IMAGE=$(sed "s/bluefin/bluefin-dx/" <<< $CURRENT_IMAGE)
        rpm-ostree rebase $NEW_IMAGE
        echo -e "\nUse `ujust dx-group` to add your user to the correct groups and complete the installation"
    fi
    if [[ "${OPTION,,}" =~ ^disable ]]; then
        if [ "$CURRENT_STATE" != "enabled" ]; then
            echo "You are currently not on a developer image"
            exit 0
        fi
        echo "Rebasing to a non developer image"
        # Remove -dx suffix from image, specifies ":" to mark the end of the image name
        NEW_IMAGE=$(sed "s/\-dx//" <<< $CURRENT_IMAGE)
        rpm-ostree rebase $NEW_IMAGE
    fi
    if gum choose "Do you want to also install the default development flatpaks?" ; then
        ujust install-system-flatpaks 1
    fi
    if gum choose "Do you want to install extra monospace fonts?" ; then
        ujust bluefin-fonts
    fi

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('System')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD {{ `id -un` }}
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks $dx="dynamic":
    #!/usr/bin/bash
    TARGET_FLATPAK_FILE="${TARGET_FLATPAK_FILE:-/etc/ublue-os/system-flatpaks.list}"
    TARGET_DEVMODE_FILE="${TARGET_DEVMODE_FILE:-/etc/ublue-os/system-flatpaks-dx.list}"
    case "$dx" in
        "0"|"1")
            ADD_DEVMODE="$dx"
            ;;
        "dynamic")
            if [[ $(jq '."image-flavor"' /usr/share/ublue-os/image-info.json) =~ dx ]] ; then
                ADD_DEVMODE=1
            fi
            ;;
        *)
            echo "Unsupported option"
            exit 1
            ;;
    esac

    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
    xargs flatpak --system -y install --or-update < $TARGET_FLATPAK_FILE
    if [ "$ADD_DEVMODE" == "1" ] ; then
        xargs flatpak --system -y install --or-update < $TARGET_DEVMODE_FILE
    fi

# Install extra system flatpaks for rebasers
[group('System')]
install-system-flatpaks-extra:
    #!/usr/bin/bash
    TARGET_FLATPAK_EXTRA_FILE="${TARGET_FLATPAK_EXTRA_FILE:-/etc/ublue-os/system-flatpaks-extra.list}"
    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
    xargs flatpak --system -y install --or-update < $TARGET_FLATPAK_EXTRA_FILE

# Alias to install both system flatpaks and extra flatpaks
[group('System')]
bluefin-apps:
    #!/usr/bin/env bash
    echo "Installing default system flatpaks..."
    just install-system-flatpaks
    echo "Installing some extra awesome applications..."
    just install-system-flatpaks-extra

# Install Brewfile bundles
[group('System')]
bluefin-ai:
    brew bundle --file /usr/share/ublue-os/homebrew/bluefin-ai.Brewfile

[group('System')]
bluefin-fonts:
    brew bundle --file /usr/share/ublue-os/homebrew/bluefin-fonts.Brewfile

[group('System')]
bluefin-k8s:
    brew bundle --file /usr/share/ublue-os/homebrew/bluefin-k8s.Brewfile

# Configure grub bootmenu visibility
[group('System')]
configure-grub:
    @/usr/libexec/configure-grub.sh

alias switch-stream := rebase-helper
alias switch-streams := rebase-helper
alias rollback-helper := rebase-helper

# Rebase assistant
[group('System')]
rebase-helper:
    @/usr/bin/ublue-rollback-helper

# Toggle IWD
[group('System')]
toggle-iwd:
    #!/usr/bin/bash
    echo -e "This script manages enabling or disabling iwd as a replacement for wpa_supplicant for Wi-Fi networking."
    echo -e "Enabling this can improve throughput, mesh networking, and reduce latency increases when scanning for networks"
    echo -e "Disabling this can improve corporate or eduroam network compatibility"
    echo -e ""
    echo -e "WARNING: Changing this will remove all saved wifi networks"
    get_current_status() {
      if [[ -f "/etc/NetworkManager/conf.d/iwd.conf" ]]; then
        echo "Enabled"
      else
        echo "Disabled"
      fi
    }
    remove_saved_networks() {
      nmcli -t -f NAME connection show | while read -r line; do sudo nmcli connection delete "$line"; done
    }
    enable_iwd() {
      sudo mkdir -p "/etc/NetworkManager/conf.d/"
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      printf "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null
      remove_saved_networks
      echo -e "iwd enabled. Reboot required to apply changes."
    }
    disable_iwd() {
      sudo rm -f "/etc/NetworkManager/conf.d/iwd.conf"
      remove_saved_networks
      echo -e "iwd disabled. Reboot required to apply changes."
    }
    # Display current status
    current_status=$(get_current_status)
    echo -e "\nCurrent iwd status: $current_status\n"
    # Prompt user for action
    CHOICE=$(ugum choose "Enable iwd" "Disable iwd" "Exit without changes")
    case "$CHOICE" in
      "Enable iwd")
        enable_iwd
        ;;
      "Disable iwd")
        disable_iwd
        ;;
      "Exit without changes")
        echo "No changes made."
        ;;
      *)
        echo "Invalid choice. Exiting without changes."
        ;;
    esac
