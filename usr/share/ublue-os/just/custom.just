benchmark:
  echo 'Running a 1 minute benchmark ...'
  stress-ng --matrix 0 -t 1m --times

assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

distrobox-universal:
  echo 'Creating Universal Development distrobox ...'
  distrobox create --image mcr.microsoft.com/devcontainers/universal:latest -n universal -Y

framework-13:
  rpm-ostree kargs --append="module_blacklist=hid_sensor_hub" --append="nvme.noacpi=1" --append="tpm_tis.interrupts=0"

fish:
  sudo lchsh -i

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
  sudo lchsh -i
