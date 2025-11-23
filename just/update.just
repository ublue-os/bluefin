# vim: set ft=make :

alias upgrade := update

# Update system, flatpaks, and containers all at once
update VERB_LEVEL="full":
    #!/usr/bin/bash
    if systemctl is-enabled ublue-update.timer | grep -q enabled;
    then
      echo "Starting the ublue-update service"
      sudo systemctl start ublue-update.service
    else
      if [ {{ VERB_LEVEL }} = "help" ]; then
          echo "Usage: just update <level>"
          echo "  <level>: Specify the verbosity level - 'full', 'minimal', or 'prompt'"
          echo "  Use 'full' to show full output of each command."
          echo "  Use 'minimal' to show minimal output and indicate success or failure."
          echo "  Use 'prompt' to prompt the user before running each command."
          exit 0
      fi

      # Function to run commands with appropriate verbosity and approval check
      update_command() {
          command=$1
          case "{{ VERB_LEVEL }}" in
              full)
                  echo "Running $command..."
                  $command
                  echo "Completed $command"
                  ;;
              minimal)
                  echo "Running $command..."
                  $command > /dev/null 2>&1
                  if [ $? -eq 0 ]; then
                      echo "Completed $command"
                  else
                      echo "Failed to complete $command"
                      exit 1
                  fi
                  ;;
              prompt)
                  printf "Do you want to run %s? [Y/n]: " "$command"
                  read user_input
                  user_input=${user_input:-Y}  # Default to Y if Enter is pressed
                  if [ "$user_input" = "Y" ] || [ "$user_input" = "y" ]; then
                      echo "Running $command..."
                      $command
                      echo "Completed $command"
                  else
                      echo "Skipped $command"
                  fi
                  ;;
              *)
                  echo "Invalid level: {{ VERB_LEVEL }}. Please use 'full', 'minimal', 'prompt' or 'help' for usage."
                  exit 1
                  ;;
          esac
      }

      # Run rpm-ostree update
      update_command "bootc update"

      # Run flatpak update
      update_command "flatpak update -y"

    fi

alias changelog := changelogs

# Show the changelog
changelogs:
    rpm-ostree db diff --changelogs

# Update device firmware
[no-exit-message]
update-firmware:
    fwupdmgr refresh --force
    fwupdmgr get-updates
    fwupdmgr update

alias auto-update := toggle-updates

# Turn automatic updates on or off
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl -q is-enabled ublue-update.timer; then
      CURRENT_STATE="Enabled"
    elif systemctl -q is-enabled rpm-ostreed-automatic.timer; then
      CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "prompt" ]; then
      echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
      echo "Enable or Disable automatic updates?"
      OPTION=$(ugum choose Enable Disable)
    elif [ "$OPTION" == "help" ]; then
      echo "Usage: ujust toggle-updates <option>"
      echo "  <option>: Specify the quick option - 'enable' or 'disable'"
      echo "  Use 'enable' to Enable automatic updates."
      echo "  Use 'disable' to Disable automatic updates."
      exit 0
    fi
    if [ "${OPTION,,}" == "enable" ]; then
      if systemctl is-enabled ublue-update.timer 2> /dev/null | grep -q not-found; then
        sudo systemctl enable --now flatpak-system-update.timer rpm-ostreed-automatic.timer
        systemctl enable --now --user flatpak-user-update.timer
      else
        sudo systemctl enable ublue-update.timer
        sudo systemctl disable --now flatpak-system-update.timer rpm-ostreed-automatic.timer
        systemctl disable --now --user flatpak-user-update.timer
      fi
    elif [ "${OPTION,,}" == "disable" ]; then
      if systemctl is-enabled ublue-update.timer 2> /dev/null | grep -q not-found; then
        sudo systemctl disable --now flatpak-system-update.timer rpm-ostreed-automatic.timer
        systemctl disable --now --user flatpak-user-update.timer
      else
        sudo systemctl disable ublue-update.timer
      fi
    fi
