benchmark:
  echo 'Running a 1 minute benchmark ...'
  stress-ng --matrix 0 -t 1m --times

assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

# Install aqua | https://aquaproj.github.io
aqua:
  @printf '\n=>Installing aqua ...\n\n'
  pushd "$(mktemp -d)"
  curl -sSfL -O https://raw.githubusercontent.com/aquaproj/aqua-installer/v2.1.1/aqua-installer
  echo "c2af02bdd15da6794f9c98db40332c804224930212f553a805425441f8331665  aqua-installer" | sha256sum -c
  chmod +x aqua-installer
  ./aqua-installer
  @printf '\n=> Make sure the ${AQUA_ROOT_DIR}/bin environment variable is added to your PATH (.bashrc/.zshrc):\n'
  @printf '\n    export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"\n'
  @printf '\n=> see https://aquaproj.github.io/docs/tutorial for more info\n'

# Install Homebrew for Linux
brew:
  echo "Installing homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to shell rc files
brew-shell:
  #!/usr/bin/env bash
  set -euxo pipefail
  echo "Adding homebrew to shell configuration"
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


cockpit:
  echo 'Enabling Cockpit'
  echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
  sudo systemctl try-restart sshd
  sudo systemctl enable --now sshd
  sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
  sudo podman container runlabel INSTALL quay.io/cockpit/ws
  sudo systemctl enable cockpit.service

code-profile:
  xdg-open https://vscode.dev/profile/github/c761b7738e9a7b02286d6d94cb2d1ecd

distrobox-mlbox:
  echo 'Assembling pytorch-nvidia mlbox distrobox ...'
  distrobox assemble create --file /usr/share/ublue-os/distrobox/pytorch-nvidia.ini

distrobox-wolfi:
  echo 'Creating WolfiOS distrobox ...'
  distrobox create --image ghcr.io/ublue-os/wolfi-toolbox:latest -n wolfi

distrobox-universal:
  echo 'Creating Universal Development distrobox ...'
  distrobox create --image mcr.microsoft.com/devcontainers/universal:latest -n universal -Y

framework-13:
  rpm-ostree kargs --append="module_blacklist=hid_sensor_hub" --append="nvme.noacpi=1" --append="tpm_tis.interrupts=0"

fish:
  sudo lchsh $USER /usr/bin/fish

gnome-extensions:
  pip install --upgrade gnome-extensions-cli
  gext install tailscale-status@maxgallup.github.com
  gext install nightthemeswitcher@romainvigier.fr
  gext install pano@elhan.io
  gext install weatheroclock@CleoMenezesJr.github.io


nix-devbox:
  echo 'Setting phasers to kill. Installing nix.'
  curl -s https://raw.githubusercontent.com/dnkmmr69420/nix-installer-scripts/main/installer-scripts/silverblue-nix-installer.sh | bash
  echo 'Installing devbox!'
  curl -fsSL https://get.jetpack.io/devbox | bash
  echo 'You MUST reboot to continue'

nix-devbox-global:
  echo 'Installing devbox global profile.'
  devbox global pull https://devbox.getfleek.dev/high
  echo 'run "devbox global run install-bash-hook" to configure bash shell'
  echo 'run "devbox global run install-zsh-hook" to configure zsh shell'
  echo 'run "devbox global run" to see other available configuration commands'

tea:
  echo 'Installing the tea package manager'
  sh <(curl https://tea.xyz)

touch:
  pip install --upgrade gnome-extensions-cli
  gext install improvedosk@nick-shmyrev.dev
  gext install gestureImprovements@gestures

update-distrobox-git:
  echo 'Installing latest git snapshot of Distrobox'
  curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --next --prefix ~/.local

yafti:
  yafti /etc/yafti.yml

zsh:
  sudo lchsh $USER /usr/bin/zsh
