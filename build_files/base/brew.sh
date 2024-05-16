#!/usr/bin/bash

set -xeou pipefail

# Convince the installer we are in CI
if [[ ! -f /.dockerenv ]]; then
    touch /.dockerenv
fi

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Brew Install Script
curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install
tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew