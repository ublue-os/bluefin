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

alias atuin := install-atuin

# Add atuin
install-atuin:
    #!/usr/bin/bash 
    shell=$(basename $SHELL) 
    if test $shell = "fish"; then 
        echo "Adding atuin to your config.fish"
        printf '\nif status is-interactive\n\tif type -q atuin\n\t\tatuin init fish | source\n\tend\nend\n' >> ${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish
    elif test $shell = "zsh"; then 
        echo "Adding atuin to your .zshrc"
        printf '\n[[ "$(command -v atuin)" ]] && eval "$(atuin init zsh)"\n' >> ${ZDOTDIR:-$HOME}/.zshrc 
    elif test $shell = "bash"; then 
        echo "Adding bash-prexec and atuin to your .bashrc" 
        printf '\n[[ -f /usr/share/bash-prexec ]] && source /usr/share/bash-prexec\n[[ "$(command -v atuin)" ]] && eval "$(atuin init bash)"\n' >> ~/.bashrc
    fi

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
# Install Google Chrome # I have a desire to make a remark here.
install-google-chrome:
    #!/usr/bin/env sh

    # Thanks to bri for the inspiration! My script is based on this example:
    # https://github.com/briorg/bluefin/blob/c62c30a04d42fd959ea770722c6b51216b4ec45b/scripts/1password.sh

    set -ouex pipefail

    echo "Installing Google Chrome"

    # On libostree systems, /opt is a symlink to /var/opt,
    # which actually only exists on the live system. /var is
    # a separate mutable, stateful FS that's overlaid onto
    # the ostree rootfs. Therefore we need to install it into
    # /usr/lib/google instead, and dynamically create a
    # symbolic link /opt/google => /usr/lib/google upon
    # boot.

    # Prepare staging directory
    mkdir -p /var/opt # -p just in case it exists

    # Prepare alternatives directory
    mkdir -p /var/lib/alternatives

    # Setup repo
    cat << EOF > /etc/yum.repos.d/google-chrome.repo
   [google-chrome]
   name=google-chrome
   baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-google
   EOF
 
   # Import signing key 
   curl --retry 3 --retry-delay 2 --retry-all-errors -sL \
       -o /etc/pki/rpm-gpg/RPM-GPG-KEY-google \
       https://dl.google.com/linux/linux_signing_key.pub
   rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-google

   # Now let's install the packages.
   rpm-ostree install google-chrome-stable

   # Clean up the yum repo (updates are baked into new images)
   rm /etc/yum.repos.d/google-chrome.repo -f

   # And then we do the hacky dance!
   mv /var/opt/google /usr/lib/google # move this over here

   #####
   # Register path symlink
   # We do this via tmpfiles.d so that it is created by the live system.
   cat >/usr/lib/tmpfiles.d/google.conf <<EOF
   L  /opt/google  -  -  -  -  /usr/lib/google
   EOF

# Setup TPM2 LUKS Autodecryption
enable-luks-autodecryption
    #!/bin/bash
    ## setup auto-unlock LUKS2 encrypted root on Fedora/Silverblue/maybe others
    set -u

   [ "$UID" -eq 0 ] || { echo "This script must be run as root."; exit 1;}

   read -p "This will modify your system and enable TPM2 auto-unlock of your LUKS partition! Are you sure you've read the script and are good with this? " -n 1 -r
   echo
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
   fi

   ## Inspect crypttab to find disk info, should look like this
   #sudo cat /etc/crypttab
   #luks-912462a2-39ce-abcd-1234-89c6c0304cb4 UUID=912462a2-39ce-abcd-1234-89c6c0304cb4 none discard
   DISK_UUID=$(sudo awk '{ print $2 }' /etc/crypttab | cut -d= -f2)
   CRYPT_DISK="/dev/disk/by-uuid/$DISK_UUID"

   ## Backup the crypttab
   if [ -f /etc/crypttab.known-good ]; then
     echo "Our backup already exists at /etc/crypttab.known-good\nExiting..."
     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
   fi
   cp -a /etc/crypttab /etc/crypttab.known-good

   ## modify the crypttab
   grep tpm2-device /etc/crypttab > /dev/null
   if [ 0 -eq $? ]; then
     echo "TPM2 already present in /etc/crypttab. Exiting..."
     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
   fi
   sed -i "s/discard/discard,tpm2-device=auto/" /etc/crypttab

   cryptsetup luksDump $CRYPT_DISK | grep systemd-tpm2 > /dev/null
   if [ 0 -eq $? ]; then
     KEYSLOT=$(cryptsetup luksDump $CRYPT_DISK|grep -A23 systemd-tpm2|grep Keyslot|awk '{print $2}')
     echo "TPM2 already present in LUKS Keyslot $KEYSLOT of $CRYPT_DISK. Exiting..."
     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
   fi

   ## Run crypt enroll
   echo "Enrolling TPM2 unlock requires your existing LUKS2 unlock password"
   echo
   systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 $CRYPT_DISK

   ## Update initramfs to respect tpm2 unlock
   rpm-ostree initramfs |grep tpm2 > /dev/null
   if [ 0 -eq $? ]; then
     echo "TPM2 already present in rpm-ostree initramfs config."
     rpm-ostree initramfs
     echo
     echo "Re-running initramfs to pickup changes above."
   fi
   rpm-ostree initramfs --enable --arg=--force-add --arg=tpm2-tss


   ## Now reboot
   echo
echo "TPM2 LUKS auto-unlock configured. Reboot now."


# References:
#  https://www.reddit.com/r/Fedora/comments/uo4ufq/any_way_to_get_systemdcryptenroll_working_on/
#  https://0pointer.net/blog/unlocking-luks2-volumes-with-tpm2-fido2-pkcs11-security-hardware-on-systemd-248.html
