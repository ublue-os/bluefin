assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

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
