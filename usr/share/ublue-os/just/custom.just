assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

cockpit:
  echo 'Enabling Cockpit'
  echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
  sudo systemctl try-restart sshd
  sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
  sudo podman container runlabel INSTALL quay.io/cockpit/ws
  sudo systemctl enable cockpit.service

gnome-extensions:
  pip install --upgrade gnome-extensions-cli
  gext install tailscale-status@maxgallup.github.com
  gext install pano@elhan.io
  gext install status-area-horizontal-spacing@mathematical.coffee.gmail.com 

touch:
  pip install --upgrade gnome-extensions-cli
  gext install improvedosk@nick-shmyrev.dev
  gext install gestureImprovements@gestures
    
zsh:
  sudo lchsh $USER /usr/bin/zsh
