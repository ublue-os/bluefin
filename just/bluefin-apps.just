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
    mkdir -p $HOME/.local/share/JetBrains/ToolboxApp/
    mv jetbrains-toolbox-"${BUILD_VERSION}"/* $HOME/.local/share/JetBrains/ToolboxApp/
    echo "Launching JetBrains Toolbox"
    $HOME/.local/share/JetBrains/ToolboxApp/bin/jetbrains-toolbox

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

# Install/update DaVinci Resolve, a closed-source video editing utility
install-resolve ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    set -eo pipefail
    SCRIPT_URL="https://raw.githubusercontent.com/zelikos/davincibox/10b4b82f0e7f121596b33595f584bc576c03bb3a/setup.sh"
    DOWNLOADDIR=$(xdg-user-dir DOWNLOAD || echo ${HOME})
    tmpdir=/var/tmp/bazzite_davincibox_setup.tmp
    mkdir -p $tmpdir
    trap "rm -rf ${tmpdir}" INT EXIT HUP
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust install-resolve <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to select Install/upgrade davincibox"
      echo "  Use 'uninstall' to select Uninstall davincibox"
      exit 0
    elif [ "$OPTION" == "" ]; then
      # Display install state and show options
      INSTALL_STATE=0
      INSTALL_STATE=$(podman container exists davincibox; echo $?)
      if (( $INSTALL_STATE == 0 )); then
        echo "Installed?: ${green}yes${n}"
      else
        echo "Installed?: ${red}no${n}"
      fi
      OPTION=$(Choose \
        "Install/upgrade davincibox" \
        "Uninstall davincibox" \
      )
      if [[ "${OPTION,,}" =~ (^install/upgrade[[:space:]]davincibox) ]]; then
        echo "This script requires you to download the DaVinci Resolve installer (should be a zip file) manually from their website and place it in ${HOME} or ${DOWNLOADDIR}"
        echo "https://www.blackmagicdesign.com/event/davinciresolvedownload"
        echo ""
        echo -e "${b}\033[3mDo not\033[0m ${b}extract the .zip contents, the script will handle everything${n}"
        echo "${lightgrey}TIP: For manual installation, see https://github.com/zelikos/davincibox${n}"
        # Get sure user reads instructions
        ugum confirm || exit 0
        # Download davincibox setup script
        SETUPSCRIPT=/tmp/davincibox_setup.sh
        wget -O $SETUPSCRIPT ${SCRIPT_URL}
        chmod +x $SETUPSCRIPT
        # Check if the installer is in HOME or DOWNLOAD
        shopt -s nullglob && possible_installers=({$HOME,$DOWNLOADDIR}/DaVinci_Resolve_{,Studio_}*_Linux.{zip,run}) \
            && shopt -u nullglob
        runfile=$(Choose ${possible_installers[@]})
        if [[ ! -z $runfile && -f $runfile ]]; then
          if [[ $runfile =~ .zip$ ]]; then
            unzip -o -d "$tmpdir" "$runfile"
            RUNFILE=$(find $tmpdir -executable -name "DaVinci_Resolve_*.run")
          else
            RUNFILE="$runfile"
          fi
          echo "Installer found: ${RUNFILE}"
        else
          echo "${red}Installer not found${n}";
          echo "${red}Please place the file DaVinci_Resolve_*_Linux.run in ${HOME} or ${DOWNLOADDIR}${n}";
          exit 1
        fi
        bash <<< "env -C ${tmpdir} $SETUPSCRIPT $RUNFILE"
        echo "davincibox was successfully installed"
      elif [[ "${OPTION,,}" =~ (^uninstall[[:space:]]davincibox) ]]; then
        ugum confirm "Confirm davincibox uninstall?" || exit 0
        # Remove the existing container
        if podman container exists davincibox >/dev/null 2>&1; then
          echo "Removing existing davincibox container"
          distrobox enter davincibox -- add-davinci-launcher remove
          podman stop davincibox
          podman rm davincibox
        else
          echo "davincibox is not installed, skip..."
          exit 0
        fi
      fi
    else
      echo "Incorrect option"
      exit 1
    fi

alias install-resolve-studio := install-resolve
alias install-davinci := install-resolve
alias install-davinci-resolve := install-resolve