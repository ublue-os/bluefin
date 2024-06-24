# vim: set ft=make :
########################
### bluefin-apps.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

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
      echo "${green}${b}Enabling${n} pmlogger"
      sudo mkdir /var/lib/pcp/tmp
      sudo mkdir /var/log/pcp/pmlogger
      sudo chown -R pcp:pcp /var/lib/pcp
      sudo chown pcp:pcp /var/log/pcp/pmlogger
      sudo systemctl enable --now pmlogger
      echo "${green}${b}Enabling${n} Cockpit"
      sudo systemctl enable cockpit.service
      echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    elif [[ "${OPTION,,}" =~ ^disable ]]; then
      echo "${red}${b}Disabling${n} Cockpit"
      sudo systemctl disable cockpit.service
      echo "Cockpit has been ${b}${red}disabled${n}"
    fi

alias jetbrains-toolbox := install-jetbrains-toolbox

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    echo "Launching JetBrains Toolbox"
    ./jetbrains-toolbox-"${BUILD_VERSION}"/jetbrains-toolbox

alias incus := install-incus

# Install and configure Incus
install-incus:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -Eq "bluefin-dx|aurora-dx" <<< $CURRENT_IMAGE
    then
        echo 'Installing and configuring Incus.'
        /usr/libexec/bluefin-incus
    else
        echo "Developer mode is currently ${b}${red}Disabled${n}."
        echo "Run \"just devmode\" to turn on Developer mode."
        exit
    fi
