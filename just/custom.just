# vim: set ft=make :

# Run a one minute system benchmark
benchmark:
    echo 'Running a 1 minute benchmark ...'
    stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience
bluefin-cli:
    @/usr/libexec/enable-bluefin-cli.sh

# Install Homebrew | https://brew.sh
brew:
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

# Install "fleek" set of packages for brew | none, low, default, high
brew-fleek level="high":
    #!/usr/bin/env bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://brew.getfleek.dev/s/fleek | bash -s -- {{ level }}

# Configure Terminal Experience
[private]
configure-terminal:
    @/usr/libexec/configure-terminal.sh

# Enable Cockpit for web-based system management | https://cockpit-project.org/
cockpit:
    echo 'Enabling Cockpit'
    echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
    sudo systemctl try-restart sshd
    sudo systemctl enable --now sshd
    sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
    sudo podman container runlabel INSTALL quay.io/cockpit/ws
    sudo systemctl enable cockpit.service
    echo 'Open Cockpit -> http://localhost:9090'

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

# Switch to the fish shell
fish:
    sudo usermod $USER --shell /usr/bin/fish 
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Install recommended GNOME extensions
gnome-extensions:
    pip install --upgrade gnome-extensions-cli
    gext install nightthemeswitcher@romainvigier.fr
    gext install pano@elhan.io
    gext install weatheroclock@CleoMenezesJr.github.io

# Enable or Disable Gnome-VRR
gnome-vrr:
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

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
jetbrains-toolbox:
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

# Install and configure Incus
incus:
    #!/usr/bin/env bash
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')

    if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
    then
        echo 'Installing and configuring Incus.'
        /usr/bin/bluefin-incus
    else
        echo "Developer mode is currently ${CURRENT_STATE}."
        echo "Run `just devmode` to turn on Developer mode."
        exit
    fi

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

# Run pytorch
pytorch:
    echo 'Follow the prompts and check the tutorial: https://docs.anaconda.com/free/anaconda/jupyter-notebooks/'
    podman pull docker.io/continuumio/miniconda3
    podman run -i -t -p 8888:8888 docker.io/continuumio/miniconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir \
    /opt/notebooks && /opt/conda/bin/jupyter notebook \
    --notebook-dir=/opt/notebooks --ip='*' --port=8888 \
    --no-browser --allow-root"

# Run Tensorflow
tensorflow:
    echo 'Follow the prompts and check the tutorial: https://www.tensorflow.org/tutorials/quickstart/beginner'
    podman pull docker.io/tensorflow/tensorflow:latest
    podman run -it -p 8888:8888 docker.io/tensorflow/tensorflow:latest-jupyter  # Start Jupyter server

# Install a better on-screen-keyboard and gesture improvements
touch:
    pip install --upgrade gnome-extensions-cli
    gext install improvedosk@nick-shmyrev.dev
    gext install gestureImprovements@gestures

# Run the yafti setup tool
yafti:
    yafti /etc/yafti.yml --force

# Switch to the zsh shell
zsh:
    sudo usermod $USER --shell /usr/bin/zsh 
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Configure docker,incus-admin,lxd,libvirt container manager permissions
dx-group:
    sudo usermod -aG docker $USER
    sudo usermod -aG incus-admin $USER
    sudo usermod -aG lxd $USER
    sudo usermod -aG libvirt $USER
    @echo "Logout to use docker, incus-admin, lxd, libvirt"

# Add atuin
atuin:
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
