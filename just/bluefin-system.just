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
    cd /tmp && stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience with Brew
bluefin-cli:
    @/usr/libexec/ublue-bling.sh

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
        echo "the current system needs an update. Please run 'ujust update'"
        echo "and reboot your system when the update is finished"
        exit
    fi
    if grep -q "dx" <<< $CURRENT_IMAGE
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
            if [[ "${CURRENT_IMAGE}" =~ "bluefin" ]]; then
              NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin/bluefin-dx/")
            elif [[ "${CURRENT_IMAGE}" =~ "aurora" ]]; then
              NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/aurora/aurora-dx/")
            fi
            rpm-ostree rebase $NEW_IMAGE
            echo ""
            echo "Use `ujust dx-group` to add your user to the correct groups and complete the installation"
        fi
    elif [ "$OPTION" = "Disable" ]
    then
        if [ "$CURRENT_STATE" = "enabled" ]
        then
            echo "Rebasing to a non developer image"
            if [[ "${CURRENT_IMAGE}" =~ "bluefin" ]]; then
              NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin-dx/bluefin/")
            elif [[ "${CURRENT_IMAGE}" =~ "aurora" ]]; then
              NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/aurora-dx/aurora/")
            fi
            rpm-ostree rebase $NEW_IMAGE
        else
            echo "You are currently not on a developer image"
        fi
    fi

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
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
      raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
      uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
      for i in ${uuids}; do
        location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
        gsettings set "${location}" opacity "{{ opacity }}"; done
      printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
      printf "Value must be greater than 0 and less than or equal to 1: %s.\n" "{{ opacity }}"
    fi

# Configure docker,incus-admin,lxd,libvirt container manager permissions
dx-group:
    #!/usr/bin/env bash
    append_group() {
    local group_name="$1"
    if ! grep -q "^$group_name:" /etc/group; then
      echo "Appending $group_name to /etc/group"
      grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
    fi
    }

    append_group docker
    append_group incus-admin
    append_group lxd
    append_group libvirt

    sudo usermod -aG docker $USER
    sudo usermod -aG incus-admin $USER
    sudo usermod -aG lxd $USER
    sudo usermod -aG libvirt $USER
    echo "Reboot system and log back in to use docker, incus-admin, lxd, libvirt."

# Configure system to use vfio and kvmfr
configure-vfio ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "dx" <<< $CURRENT_IMAGE
    then
      DEVMODE="enabled"
    else
      DEVMODE="disabled"
    fi
    if [ "$DEVMODE" == "disabled" ]; then
      echo 'Please run "ujust devmode" first'
      exit 0
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust configure-vfio <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'vfio-on' to select Enable VFIO drivers"
      echo "  Use 'vfio-off' to select Disable VFIO drivers"
      echo "  Use 'kvmfr' to select Autocreate Looking-Glass shm"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}VFIO and kvmfr Configuration${normal}"
      echo "This is only used for GPU passthrough of a secondary dGPU."
      echo "It will enable vfio and configure kvmfr for use with $(Urllink "https://looking-glass.io" "Looking Glass")"
      echo "If you do not plan to use any of this then press ESC."
      echo "${bold}NOTE:${normal} Since this is a niche use case, support will be ${b}very limited${n}"
      OPTION=$(Choose \
        "Enable VFIO drivers" \
        "Disable VFIO drivers" \
        "Enable kvmfr module" \
      )
    fi
    if [[ "${OPTION,,}" =~ (^enable[[:space:]]vfio|vfio-on) ]]; then
      echo "Enabling VFIO..."
      VIRT_TEST=$(rpm-ostree kargs)
      CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
      VENDOR_KARG="unset"
      if [[ ${VIRT_TEST} == *kvm.report_ignored_msrs* ]]; then
        echo 'add_drivers+=" vfio vfio_iommu_type1 vfio-pci "' | sudo tee /etc/dracut.conf.d/vfio.conf
        rpm-ostree initramfs --enable
        if [[ ${CPU_VENDOR} == "AuthenticAMD" ]]; then
          VENDOR_KARG="amd_iommu=on"
        elif [[ ${CPU_VENDOR} == "GenuineIntel" ]]; then
          VENDOR_KARG="intel_iommu=on"
        fi
        if [[ ${VENDOR_KARG} == "unset" ]]; then
          echo "Failed to get CPU vendor, exiting..."
          exit 1
        else
          rpm-ostree kargs \
            --append-if-missing="${VENDOR_KARG}" \
            --append-if-missing="iommu=pt" \
            --append-if-missing="rd.driver.pre=vfio_pci" \
            --append-if-missing="vfio_pci.disable_vga=1"
          echo "VFIO will be enabled on next boot, make sure you enable IOMMU, VT-d or AMD-v in your BIOS!"
          echo "Please understand that since this is such a niche use case, support will be very limited!"
          echo "To add your unused/second GPU device ids to the vfio driver by running"
          echo 'rpm-ostree kargs --append-if-missing="vfio-pci.ids=xxxx:yyyy,xxxx:yyzz"'
          echo "NOTE: Your second GPU will not be usable by the host after you do this!"
        fi
      fi
    elif [[ "${OPTION,,}" =~ (^disable[[:space:]]vfio|vfio-off) ]]; then
      echo ""
      echo "Make sure you have ${b}disabled autostart of all VMs using VFIO${n} before continuing!"
      CONFIRM=$(Choose Cancel Continue)
      if [ "$CONFIRM" == "Continue" ]; then
        echo "Disabling VFIO..."
        VFIO_IDS="$(rpm-ostree kargs | sed -E 's/.+(vfio_pci.ids=.+\s)/\1/' | awk '{ print $1 }' | grep vfio_pci.ids)"
        VFIO_IDS_KARG=""
        if [ -n "$VFIO_IDS" ]; then
          echo "Found VFIO ids in kargs, adding the below line to removal list"
          echo "$VFIO_IDS"
          VFIO_IDS_KARG="--delete-if-present=\"$VFIO_IDS\""
        fi
        echo "Removing dracut modules"
        sudo rm /etc/dracut.conf.d/vfio.conf
        rpm-ostree initramfs --enable
        rpm-ostree kargs \
        --delete-if-present="iommu=pt" \
        --delete-if-present="iommu=on" \
        --delete-if-present="amd_iommu=on" \
        --delete-if-present="intel_iommu=on" \
        --delete-if-present="rd.driver.pre=vfio_pci" \
        --delete-if-present="vfio_pci.disable_vga=1" \
        --delete-if-present="vfio_pci.disable_vga=0" \
        $VFIO_IDS_KARG
      fi
    elif [[ "${OPTION,,}" =~ kvmfr ]]; then
      sudo /usr/libexec/bluefin-dx-kvmfr-setup
    fi

# Install system flatpaks for rebasers
[private]
install-system-flatpaks:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
        FLATPAKS="bluefin_flatpaks/flatpaks"
    elif [[ ${BASE_IMAGE_NAME} == 'kinoite' ]]; then
        FLATPAKS="aurora_flatpaks/flatpaks"
    fi
    FLATPAK_LIST="$(curl https://raw.githubusercontent.com/ublue-os/bluefin/main/${FLATPAKS} | tr '\n' ' ')"
    flatpak --system -y install --or-update ${FLATPAK_LIST}

# Configure grub bootmenu visibility
configure-grub:
    @/usr/libexec/configure-grub.sh

alias rollback-helper := rebase-helper
alias switch-channel := rebase-helper

# Rebase assistant
rebase-helper:
    @/usr/bin/ublue-rollback-helper

# Toggle tailscale
toggle-tailscale:
    #!/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    source /usr/lib/os-release

    TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"

    if [ "$TAILSCALED_STATUS" == "enabled" ] || [ "$TAILSCALED_STATUS" == "disabled" ]; then
        TAILSCALED="Installed"
    else
        TAILSCALED="Not Found"
        echo "${b}${red}Unable to enable or disable Tailscale.${n}"
        echo "The tailscaled service must be present and either enabled or disabled to run this script."
        echo "tailscaled service status: $TAILSCALED_STATUS"
    fi


    if [ "$TAILSCALED" == "Installed" ]; then
      echo "Enable or disable Tailscale?"
      TS_OPTION=$(ugum choose Enable Disable)

      # gnome-extensions is only available on Bluefin (Gnome)
      if [ "$VARIANT" == "silverblue" ]; then
        TAILSCALE_QS="$(gnome-extensions list | grep -q "tailscale@joaophi.github.com"; echo $?)"
        if [ "$TAILSCALE_QS" == 0 ]; then
          TAILSCALE_QS="Installed"
        else
          echo "The Tailscale QS extension for Gnome is not installed. Please install it and then run this script again."
        fi

        if [ "$TS_OPTION" = "Enable" ]; then
          gnome-extensions enable tailscale@joaophi.github.com
        elif [ "$TS_OPTION" = "Disable" ]; then
          gnome-extensions disable tailscale@joaophi.github.com
        fi
      fi

      if [ "$TS_OPTION" = "Enable" ]; then
        systemctl enable --now tailscaled
        TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
        if [ "$TAILSCALED_STATUS" == "enabled" ]; then
          echo "${b}${green}Tailscale is enabled.${n}"
          echo "If this is your first time using Tailscale, setup is necessary."
          echo "Refer to Tailscale's documentation at https://tailscale.com/kb/1346/start."
        fi
      elif [ "$TS_OPTION" = "Disable" ]; then
        systemctl disable --now tailscaled
        TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
        if [ "$TAILSCALED_STATUS" == "disabled" ]; then
          echo "${b}${red}Tailscale is disabled.${n}"
        fi
      fi
    fi
