# vim: set ft=make :
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

alias brew := install-brew

# Install Homebrew | https://brew.sh
install-brew:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if [[ ! -f "/var/home/linuxbrew/.linuxbrew/bin" || ! -x "/var/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        echo "${b}Brew Installation${n}"
        echo "Please ${b}IGNORE${n} everything the installer tells you to do at the end"
        echo "We have already done it for you! You just need to close and re-open the terminal after installation"
        echo "Do you understand?"
        echo "Please type in \"YES I UNDERSTAND\" and press enter"
        read ACCEPT
        if [ "$ACCEPT" == "YES I UNDERSTAND" ]; then
          /usr/bin/bash -c '/usr/libexec/brew-install'
        else
          echo "Capitalization matters when you type \"YES I UNDERSTAND\""
        fi
    fi
    # if /etc/profile.d/brew.sh already exists, replace it with /usr/etc/profile.d/brew.sh
    if [ -f /etc/profile.d/brew.sh ]; then
        if [ -f /usr/etc/profile.d/brew.sh ]; then
            sudo cp /usr/etc/profile.d/brew.sh /etc/profile.d/brew.sh
        fi
    fi

alias brew-fleek := install-brew-fleek

# Install "fleek" set of packages for brew | none, low, default, high
install-brew-fleek level="high":
    #!/usr/bin/env bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://brew.getfleek.dev/s/fleek | bash -s -- {{ level }}

alias cockpit := setup-cockpit

# Enable Cockpit for web-based system management | https://cockpit-project.org/
setup-cockpit ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    COCKPIT_SERVICE_STATUS="$(systemctl is-enabled cockpit.service)"
    if [ "$COCKPIT_SERVICE_STATUS" == "enabled" ]; then
      COCKPIT_SERVICE_STATUS="${green}${b}Enabled${n}"
    elif [ "$COCKPIT_SERVICE_STATUS" == "disabled" ]; then
      COCKPIT_SERVICE_STATUS="${red}${b}Disabled${n}"
    else
      COCKPIT_SERVICE_STATUS="${invert}${b}Not Installed${n}"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust setup-cockpit <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to select Install Cockpit"
      echo "  Use 'enable' to select Enable Cockpit"
      echo "  Use 'disable' to select Disable Cockpit"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}Cockpit Setup${normal}"
      echo "Cockpit service is currently: $COCKPIT_SERVICE_STATUS"
      if [[ "${COCKPIT_SERVICE_STATUS}" =~ "Not Installed" ]]; then
        OPTION=$(Choose "Install Cockpit" "Cancel")
      else
        OPTION=$(Choose "Enable Cockpit" "Disable Cockpit")
      fi
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
      echo 'Installing Cockpit'
      echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
      sudo systemctl try-restart sshd
      sudo systemctl enable --now sshd
      sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
      sudo podman container runlabel INSTALL quay.io/cockpit/ws
      OPTION="Enable Cockpit"
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
      echo "${green}${b}Enabling${n} Cockpit"
      sudo systemctl enable cockpit.service
      echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    elif [[ "${OPTION,,}" =~ ^disable ]]; then
      echo "${red}${b}Disabling${n} Cockpit"
      sudo systemctl disable cockpit.service
      echo "Cockpit has been ${b}${red}disabled${n}"
    fi
