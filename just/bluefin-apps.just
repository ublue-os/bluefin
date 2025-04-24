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

# alias for setup-cockpit
[group('Apps')]
cockpit:
    @ujust setup-cockpit

# Enable Cockpit for web-based system management | https://cockpit-project.org/
[group('Apps')]
setup-cockpit ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    MANAGED_COCKPIT_CONTAINER="cockpit-ws"

    if sudo podman container exists $MANAGED_COCKPIT_CONTAINER ; then
        COCKPIT_CONTAINER_STATUS_PRETTY="${green}${b}Installed${n}"
        COCKPIT_CONTAINER_STATUS=1
    else
        COCKPIT_CONTAINER_STATUS_PRETTY="${invert}${b}Not installed${n}"
        COCKPIT_CONTAINER_STATUS=0
    fi

    COCKPIT_SERVICE_STATUS="$(systemctl is-enabled cockpit.service)"
    if [ "$COCKPIT_SERVICE_STATUS" == "enabled" ]; then
        COCKPIT_SERVICE_STATUS="${green}${b}Enabled${n}"
    elif [ "$COCKPIT_SERVICE_STATUS" == "disabled" ]; then
        COCKPIT_SERVICE_STATUS="${red}${b}Disabled${n}"
    else
        COCKPIT_SERVICE_STATUS="${invert}${b}Not installed${n}"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        cat <<EOF
    Usage: ujust setup-cockpit <option>
      <option>: Specify the quick option to skip the prompt
      Use 'install' to select Install Cockpit
      Use 'enable' to select Enable Cockpit
      Use 'disable' to select Disable Cockpit
      Use 'uninstall' to select Uninstall Cockpit
    EOF
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Cockpit Setup${normal}"
        echo "Cockpit service is currently: $COCKPIT_SERVICE_STATUS"
        echo "The Cockpit container is currently: $COCKPIT_CONTAINER_STATUS_PRETTY"
        if [[ "${COCKPIT_CONTAINER_STATUS}" -eq 0 ]]; then
            echo "Warning: This will enable ssh password login because Cockpit requires it."
            OPTION=$(Choose "Install Cockpit" "Cancel")
        else
            OPTION=$(Choose "Enable Cockpit" "Disable Cockpit" "Uninstall Cockpit")
        fi
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "${blue}${b}Installing Cockpit${n}"
        sudo /bin/bash <<EOF
    [ ! -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && echo -e "# File managed by ujust cockpit\nPasswordAuthentication yes" > /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q enable --now sshd
    if ! podman image exists quay.io/cockpit/ws ; then
        podman pull quay.io/cockpit/ws:latest
    fi
    podman container runlabel -q --name $MANAGED_COCKPIT_CONTAINER RUN quay.io/cockpit/ws
    podman container runlabel -q INSTALL quay.io/cockpit/ws systemctl enable cockpit.service
    EOF
        OPTION="Enable Cockpit"
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        sudo /bin/bash <<EOF
    echo "${green}${b}Enabling${n} Cockpit"
    systemctl -q enable --now cockpit.service
    podman start $MANAGED_COCKPIT_CONTAINER
    echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    EOF
    fi
    if [[ "${OPTION,,}" =~ ^disable ]]; then
        echo "${red}${b}Disabling${n} Cockpit"
        sudo /bin/bash <<EOF
    systemctl -q disable cockpit.service
    podman stop $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${b}${red}disabled${n}"
    fi
    if [[ "${OPTION,,}" =~ ^uninstall ]] ; then
        sudo /bin/bash <<EOF
    [ -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && rm -f /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q disable --now cockpit.service
    rm -f /etc/systemd/system/cockpit.service
    podman stop -i $MANAGED_COCKPIT_CONTAINER
    podman rm -f $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${red}${b}uninstalled${n}"
    fi

# alias for install-jetbrains-toolbox
[group('Apps')]
jetbrains-toolbox:
    @ujust install-jetbrains-toolbox

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
[group('Apps')]
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

# alias for install-incus
[group('Apps')]
incus:
    @ujust install-incus

# Install OpenTabletDriver, an open source, cross-platform, user-mode tablet driver
[group('Apps')]
install-opentabletdriver:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    echo "Installer for OpenTabletDriver..."
    echo "${bold}Install or Remove OpenTabletDriver${normal}"
    OPTION=$(Choose "Install" "Uninstall" "Exit")
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "Installing OpenTabletDriver..."
        curl -s https://api.github.com/repos/OpenTabletDriver/OpenTabletDriver/releases/latest \
        | jq -r '.assets | sort_by(.created_at) | .[] | select (.name|test("opentabletdriver.*tar.gz$")) | .browser_download_url' \
        | wget -qi - -O /tmp/OpenTabletDriver/opentabletdriver.tar.gz && \
        tar --strip-components=1 -xvzf /tmp/OpenTabletDriver/opentabletdriver.tar.gz -C /tmp/OpenTabletDriver && \
        pkexec cp /tmp/OpenTabletDriver/etc/udev/rules.d/70-opentabletdriver.rules /etc/udev/rules.d/71-opentabletdriver.rules && \
        rm -rf /tmp/OpenTabletDriver && \
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
        flatpak --system install -y flathub net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/OpenTabletDriver && \
        flatpak override --user --filesystem=xdg-config/OpenTabletDriver net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/systemd/user && \
        curl -s https://raw.githubusercontent.com/flathub/net.opentabletdriver.OpenTabletDriver/refs/heads/master/scripts/opentabletdriver.service > $HOME/.config/systemd/user/opentabletdriver.service  && \
        systemctl --user daemon-reload && \
        systemctl enable --user --now opentabletdriver.service
    elif [[ "${OPTION,,}" =~ ^uninstall ]]; then
        echo "Uninstalling OpenTabletDriver..."
        pkexec rm /etc/udev/rules.d/71-opentabletdriver.rules && \
        flatpak --system remove -y flathub net.opentabletdriver.OpenTabletDriver
    else
        echo "Have a good day :)!"
    fi

# Install and configure Incus
[group('Apps')]
install-incus:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if ! grep -e "-dx" <<< $CURRENT_IMAGE ; then
        echo "Developer mode is currently ${b}${red}Disabled${n}."
        echo "Run \"just devmode\" to turn on Developer mode."
        exit
    fi
    echo 'Installing and configuring Incus.'
    /usr/libexec/bluefin-incus

# Install Kubernetes CLI dev tools
[group('Apps')]
install-k8s-dev-tools:
    #!/usr/bin/bash
    echo "Adding Kubernetes command line tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/kubernetes.Brewfile

# Set up command-not-found for Homebrew
[group('Apps')]
setup-brew-not-found ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        echo "Usage: ujust setup-brew-not-found <option>"
        echo "  <option>: Specify the quick option to skip the prompt"
        echo "  Use 'enable' to select Enable Brew Not Found"
        echo "  Use 'disable' to select Disable Brew Not Found"
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Brew command-not-found Setup${normal}"
        OPTION=$(Choose "Enable Brew command-not-found" "Disable Brew command-not-found")
    fi

    set -euo pipefail

    BREW_BINARY=/home/linuxbrew/.linuxbrew/bin/brew
    HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$($BREW_BINARY --repository)}
    if ! $BREW_BINARY -h > /dev/null; then
      echo "Make sure Homebrew is installed first. Check journalctl -e -u brew-setup.service"
      exit
    fi

    if [[ "${OPTION,,}" =~ ^enable ]]; then
        $BREW_BINARY tap homebrew/command-not-found
        pkexec tee /etc/profile.d/brew-command-not-found.sh > /dev/null <<EOF
    # Check for interactive bash or zsh and that we haven't already been sourced
    if [[ -d /home/linuxbrew/.linuxbrew && \$- == *i* && BREW_COMMAND_NOT_FOUND != 1 ]] ; then
      HB_CNF_HANDLER="${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
      [ -f "\$HB_CNF_HANDLER" ] && source "\$HB_CNF_HANDLER"
      export BREW_COMMAND_NOT_FOUND=1
    fi
    EOF
        # Necessary for fish since just having a script sourcing it does not work
        pkexec ln -sf "${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-command-not-found/handler.fish" /etc/fish/conf.d/brew-cnf-handler.fish
        echo "Brew command-not-found has been ${b}${green}enabled${n}"
    fi

    if [[ "${OPTION,,}" =~ ^disable ]]; then
        $BREW_BINARY untap homebrew/command-not-found
        FILES_TO_BE_REMOVED=()
        [ -f /etc/profile.d/brew-command-not-found.sh ] && FILES_TO_BE_REMOVED+=("/etc/profile.d/brew-command-not-found.sh")
        [ -f /etc/fish/conf.d/brew-command-not-found.fish ] && FILES_TO_BE_REMOVED+=("/etc/fish/conf.d/brew-command-not-found.fish")
        pkexec rm -f "${FILES_TO_BE_REMOVED[@]}"
      echo "Brew command-not-found has been ${b}${red}disabled${n}"
    fi

# Install gaming flatpaks
# 23.08 runtime versions are needed for Heroic/Lutris
[group('Apps')]
install-gaming-flatpaks:
    #!/usr/bin/env bash
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --system -y install --or-update app/com.valvesoftware.Steam/x86_64/stable \
                                            app/com.heroicgameslauncher.hgl/x86_64/stable \
                                            app/net.lutris.Lutris/x86_64/stable \
                                            app/com.vysp3r.ProtonPlus/x86_64/stable \
                                            app/com.dec05eba.gpu_screen_recorder/x86_64/stable \
                                            app/com.github.Matoking.protontricks/x86_64/stable \
                                            runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08 \
                                            runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable \
                                            runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 \
                                            runtime/com.valvesoftware.Steam.Utility.steamtinkerlaunch/x86_64/stable
