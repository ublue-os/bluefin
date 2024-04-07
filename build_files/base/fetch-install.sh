#!/usr/bin/bash

set -oue pipefail

# Starship Shell Prompt
curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Brew Install Script
wget https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -O /usr/libexec/brew-install
chmod +x /usr/libexec/brew-install

# Flatpak Remotes
mkdir -p /usr/etc/flatpak/remotes.d
wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d

# Topgrade Install
pip install --prefix=/usr topgrade