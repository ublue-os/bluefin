# vim: set ft=make :
# These are convenience shortcuts, they should not be specific to a desktop, aimed to be rather generic things for both Aurora and Bluefin

uid := `id -u`
shell := `grep :$(id -u): /etc/passwd | cut -d: -f7`

# Boot into this device's BIOS/UEFI screen
bios:
    #!/usr/bin/bash
    if [ ! -d /sys/firmware/efi ]; then
      echo "Rebooting to legacy BIOS from OS is not supported."
      exit 1
    fi

    if gum confirm "Reboot into BIOS?" ; then
      systemctl reboot --firmware-setup
    fi

# Show BIOS info
bios-info:
    #!/usr/bin/bash
    sudo bash <<'EOF'
    echo "Manufacturer: $(dmidecode -s baseboard-manufacturer)"
    echo "Product Name: $(dmidecode -s baseboard-product-name)"
    echo "Version: $(dmidecode -s bios-version)"
    echo "Release Date: $(dmidecode -s bios-release-date)"
    EOF

clean-system:
    #!/usr/bin/bash
    if gum confirm "Prune all Podman images and volumes?"; then
        podman image prune -af
        podman volume prune -f
    fi

    if command -v docker >/dev/null 2>&1; then
      if gum confirm "Prune all Docker images and volumes?"; then
        docker image prune -af
        docker volume prune -f
      fi
    fi

    flatpak uninstall --unused
    rpm-ostree cleanup -bm
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        brew autoremove
        brew cleanup
    fi

# Show all messages from this boot
logs-this-boot:
    sudo journalctl --no-hostname -b 0

# Show all messages from last boot
logs-last-boot:
    sudo journalctl --no-hostname -b -1

# Enroll Nvidia driver & KMOD signing key for secure boot - Enter password "universalblue" if prompted
enroll-secure-boot-key:
    #!/usr/bin/bash
    ENROLLMENT_PASSWORD="universalblue"
    sudo bash <<EOF
    mokutil --timeout -1
    echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "/etc/pki/akmods/certs/akmods-ublue.der"
    EOF
    echo 'At next reboot, the mokutil UEFI menu UI will be displayed (*QWERTY* keyboard input and navigation).\nThen, select "Enroll MOK", and input "universalblue" as the password'

# Toggle display of the user-motd in terminal
toggle-user-motd:
    #!/usr/bin/bash
    if [ -e "${HOME}/.config/no-show-user-motd" ] ; then
      if gum confirm "Would you like to enable the MOTD?" ; then
        rm -f "${HOME}/.config/no-show-user-motd"
        echo "MOTD will now be shown on login."
        exit 0
      fi
    fi
    if gum confirm "Would you like to disable the MOTD?" ; then
      mkdir -p "${HOME}/.config"
      touch "${HOME}/.config/no-show-user-motd"
      echo "MOTD will not be shown anymore."
      exit 0
    fi

# Check for local overrides
check-local-overrides:
    #!/usr/bin/bash
    RESET="\x1b[0m"
    if [ "${NO_COLOR}" == 1 ]; then
        BLUE_COLOR=""
        GREEN_COLOR=""
        YELLOW_COLOR=""
    else
        BLUE_COLOR="${BLUE_COLOR:-\x1b[38;5;117m}"
        GREEN_COLOR="${GREEN_COLOR:-\x1b[38;5;85m}"
        YELLOW_COLOR="${YELLOW_COLOR:-\x1b[93m}"
    fi

    diff -qr \
      --suppress-common-lines \
      --color="always" \
      --exclude "passwd*" \
      --exclude "group*" \
      --exclude="subgid*" \
      --exclude="subuid*" \
      --exclude="machine-id" \
      --exclude="adjtime" \
      --exclude="fstab" \
      --exclude="system-connections" \
      --exclude="shadow*" \
      --exclude="gshadow*" \
      --exclude="ssh_host*" \
      --exclude="cmdline" \
      --exclude="crypttab" \
      --exclude="hostname" \
      --exclude="localtime" \
      --exclude="locale*" \
      --exclude="*lock" \
      --exclude=".updated" \
      --exclude="*LOCK" \
      --exclude="vconsole*" \
      --exclude="00-keyboard.conf" \
      --exclude="grub" \
      --exclude="system.control*" \
      --exclude="cdi" \
      --exclude="default.target" \
      /usr/etc /etc 2>/dev/null | sed \
          -e '/Binary\ files\ /d ; /Common subdirectories/d' \
          -e "/Files/ s/^/${BLUE_COLOR}&/g" \
          -e "/Files/ s/\$/&${RESET}/g" \
          -e "/Only in/ s/^/${GREEN_COLOR}&/g" \
          -e "/Only in/ s/\$/&${RESET}/g" \
          -e "s/\:.*/${RESET}${YELLOW_COLOR}&${RESET}/g"

# Gather device info to a pastebin
device-info:
    #!/usr/bin/bash
    if ! gum confirm "Submit information to the CentOS pastebin?" ; then
        exit 0
    fi

    cat &> /tmp/deviceinfo-out <<EOF
    --#--# sudo bootc status --verbose:
    $(sudo bootc status --verbose)
    --#--# fpaste --sysinfo --printonly:
    $(fpaste --sysinfo --printonly)
    --#--# flatpak list --columns=application,version,options:
    $(flatpak list --columns=application,version,options)
    EOF

    cat /tmp/deviceinfo-out | fpaste

# Measure Idle Power Draw
check-idle-power-draw:
    #!/usr/bin/bash
    if ! command -v powerstat ; then
        echo "Powerstat is not available"
        exit 1
    fi
    sudo powerstat -a -r

# Run a one minute system benchmark
[group('System')]
benchmark:
    #!/usr/bin/env bash
    if ! command -v "stress-ng" ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo "Running a 1 minute benchmark ..."
    trap popd EXIT
    pushd "$(mktemp -d)"
    stress-ng --matrix 0 -t 1m --times
