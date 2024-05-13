#!/usr/bin/bash

set -ouex pipefail

# Starship Shell Prompt
curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Brew Install Script
curl -Lo /usr/libexec/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /usr/libexec/brew-install

# Flatpak Remotes
mkdir -p /usr/etc/flatpak/remotes.d
curl -Lo /usr/etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Topgrade Install
pip install --prefix=/usr topgrade

# Install ublue-update -- breaks with packages.json disable staging to use bling.
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
rpm-ostree install ublue-update

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Copy over ublue-update config
cp /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml
