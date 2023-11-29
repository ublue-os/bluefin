# vim: set ft=make :

# Run a one minute system benchmark
benchmark:
    echo 'Running a 1 minute benchmark ...'
    stress-ng --matrix 0 -t 1m --times

# Assemble distrobox containers
assemble:
    echo 'Assembling and replacing distroboxes ...'
    distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

# Install aqua | https://aquaproj.github.io
aqua:
    #!/usr/bin/env bash
    printf '\n=>Installing aqua ...\n\n'
    pushd "$(mktemp -d)"
    curl -sSfL -O https://raw.githubusercontent.com/aquaproj/aqua-installer/v2.1.1/aqua-installer
    echo "c2af02bdd15da6794f9c98db40332c804224930212f553a805425441f8331665  aqua-installer" | sha256sum -c
    chmod +x aqua-installer
    ./aqua-installer
    printf '\n=> Make sure the ${AQUA_ROOT_DIR}/bin environment variable is added to your PATH (.bashrc/.zshrc):\n'
    printf '\n    export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"\n'
    printf '\n=> see https://aquaproj.github.io/docs/tutorial for more info\n'

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

# Assemble a Pytorch distrobox (Nvidia only)
distrobox-mlbox:
    echo 'Assembling pytorch-nvidia mlbox distrobox ...'
    distrobox assemble create --file /usr/share/ublue-os/distrobox/pytorch-nvidia.ini

# Create a Wolfi OS container | https://github.com/wolfi-dev
distrobox-wolfi:
    echo 'Creating WolfiOS distrobox ...'
    distrobox create --image ghcr.io/ublue-os/wolfi-toolbox:latest -n wolfi

# Create a universal developer container
distrobox-universal:
    echo 'Creating Universal Development distrobox ...'
    distrobox create --image mcr.microsoft.com/devcontainers/universal:latest -n universal -Y

# Switch to the fish shell
fish:
    sudo usermod $USER --shell /usr/bin/fish 
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Install recommended GNOME extensions
gnome-extensions:
    pip install --upgrade gnome-extensions-cli
    gext install tailscale-status@maxgallup.github.com
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

# Install nix and Devbox
nix-devbox:
    echo 'Setting phasers to kill. Installing nix.'
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo 'Installing devbox!'
    curl -fsSL https://get.jetpack.io/devbox | bash
    echo 'You MUST reboot to continue'

# Remove nix
nix-remove:
    echo 'Setting phasers to stun. Removing nix.'
    /nix/nix-installer uninstall

# Install nix and Devbox (Global Profile)
nix-devbox-global:
    echo 'Installing devbox global profile.'
    devbox global pull https://devbox.getfleek.dev/high
    echo 'run "devbox global run install-hook-bash" to configure bash shell'
    echo 'run "devbox global run install-hook-zsh" to configure zsh shell'
    echo 'run "devbox global run" to see other available configuration commands'

# Enable podmansh as user shell (EXPERIMENTAL)
podmansh:
    sudo mkdir -p /etc/containers/systemd/users/${UID}
    sudo cp /usr/share/ublue-os/quadlets/podmansh.container /etc/containers/systemd/users/${UID}/podmansh.container
    sudo usermod $USER --shell /usr/bin/podmansh
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"
    systemctl --user start podman.socket
    loginctl enable-linger $(whoami)

    podman pull ghcr.io/ublue-os/ubuntu-toolbox:latest

    systemctl --user daemon-reload
    systemctl --user stop podmansh.service
    systemctl --user start podmansh.service

    @echo "Shell now switched to podmansh. Spawn a new terminal to get going!"
    @echo "By default, the shell will be Bash. To override it, create ~/.profile with your preferred shell"
    @echo "Note: That shell must exist in the toolbox!"
    @echo "To ensure a smooth experience within VSCode, please add the following to your settings.json:"
    @echo "---"
    @echo "\"terminal.integrated.profiles.linux\": {"
    @echo "  \"podmansh zsh\": {"
    @echo "     \"path\": \"podmansh\","
    @echo "     \"args\": [\"-c\", \"cd \${workspaceFolder}; exec zsh\"]"
    @echo "  }"
    @echo "}"
    @echo "---"
    @echo "Please make sure you have the following environment variable set WITHIN the container:"
    @echo "---"
    @echo "export DOCKER_HOST=unix:///var/run/podman/podman.sock"
    @echo "---"
    @echo "Happy Podmansh'ing!"

# Switch podmansh to another image (EXPERIMENTAL)
podmansh-switch IMAGE:
    sudo sed -i "/Image\=.*$/c Image\={{ IMAGE }}" /etc/containers/systemd/users/${UID}/podmansh.container
    podman pull {{ IMAGE }}
    podman rm -f podmansh
    systemctl --user daemon-reload
    systemctl --user start podmansh.service
    echo "Image now switched to {{ IMAGE }}"

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

# A preview of what the update system would look like in the future
update-ng:
    echo 'Upgrading system...'
    sudo bootc upgrade
    echo 'Upgrading flatpaks...'
    flatpak update -y
    echo 'Assembling and replacing distroboxes ...'
    distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

# Upgrade Distrobox to the latest git version
distrobox-git:
    echo 'Installing latest git snapshot of Distrobox'
    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --next --prefix ~/.local

# Run the yafti setup tool
yafti:
    yafti /etc/yafti.yml --force

# Switch to the zsh shell
zsh:
    sudo usermod $USER --shell /usr/bin/zsh 
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Enable docker on the system
docker:
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    newgrp docker
