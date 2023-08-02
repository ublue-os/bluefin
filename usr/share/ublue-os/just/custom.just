benchmark:
  echo 'Running a 1 minute benchmark ...'
  stress-ng --matrix 0 -t 1m --times

assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

brew:
  echo "Installing homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
