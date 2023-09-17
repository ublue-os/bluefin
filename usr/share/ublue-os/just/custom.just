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

# Install Homebrew for Linux
brew:
  echo "Installing homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to shell rc files
brew-shell:
  #!/usr/bin/env bash
  set -euxo pipefail
  echo "Adding homebrew to shell configuration"
  touch $HOME/.zprofile
  touch $HOME/.bash_profile
  if grep -q "linuxbrew" $HOME/.zprofile
  then
    echo "Brew configuration already present in .zprofile"
  else 
    echo "Adding Brew configuration to .zprofile"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zprofile
  fi
  if grep -q "linuxbrew" $HOME/.bash_profile
  then
    echo "Brew configuration already present in .bash_profile"
  else 
    echo "Adding Brew configuration to .bash_profile"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bash_profile
  fi

# Enable Cockpit for web-based system management | https://cockpit-project.org/
cockpit:
  echo 'Enabling Cockpit'
  echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
  sudo systemctl try-restart sshd
  sudo systemctl enable --now sshd
  sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
  sudo podman container runlabel INSTALL quay.io/cockpit/ws
  sudo systemctl enable cockpit.service

# Import a devcontainers profile for VSCode
code-profile:
  xdg-open https://vscode.dev/profile/github/c761b7738e9a7b02286d6d94cb2d1ecd

# Rebase to a stock Bluefin image
devmode-off:
  #!/usr/bin/env bash
  CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
  if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
  then
      echo "Rebasing to a non developer image"
      NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin-dx/bluefin/")
      rpm-ostree rebase $NEW_IMAGE
  else
      echo "You are currently not on a developer image"
  fi

# Rebase to the Bluefin Developer Experience image
devmode-on:
  #!/usr/bin/env bash
  CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
  if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
  then
      echo "You are already on a developer image"
  else
      echo "Rebasing to a developer image"
      NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin/bluefin-dx/")
      rpm-ostree rebase $NEW_IMAGE
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

# Add boot parameters needed for a Framework 13 laptop
framework-13:
  rpm-ostree kargs --append="module_blacklist=hid_sensor_hub" --append="nvme.noacpi=1" --append="tpm_tis.interrupts=0" --append="rd.luks.options=discard"

# Switch to the fish shell
fish:
  sudo lchsh $USER /usr/bin/fish 

# Install recommended GNOME extensions
gnome-extensions:
  pip install --upgrade gnome-extensions-cli
  gext install tailscale-status@maxgallup.github.com
  gext install nightthemeswitcher@romainvigier.fr
  gext install pano@elhan.io
  gext install weatheroclock@CleoMenezesJr.github.io

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
  sudo lchsh $USER /usr/bin/podmansh
  podman pull ghcr.io/ublue-os/ubuntu-toolbox:latest
  
  systemctl --user daemon-reload
  systemctl --user stop podmansh.service
  systemctl --user start podmansh.service
  echo "Shell now switched to podmansh. Spawn a new terminal to get going!"
  echo "By default, the shell will be Bash. To override it, create ~/.profile with your preferred shell"
  echo "Note: That shell must exist in the toolbox!"

# Switch podmansh to another image (EXPERIMENTAL)
podmansh-switch IMAGE:
  sudo sed -i "/Image\=.*$/c Image\={{IMAGE}}" /etc/containers/systemd/users/${UID}/podmansh.container
  podman pull {{IMAGE}}
  podman rm -f podmansh
  systemctl --user daemon-reload
  systemctl --user start podmansh.service
  echo "Image now switched to {{IMAGE}}"

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
  yafti /etc/yafti.yml

# Switch to the zsh shell
zsh:
  sudo lchsh $USER /usr/bin/zsh 

docker:
  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER
  newgrp docker
