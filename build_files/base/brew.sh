#!/usr/bin/bash

set -xeou pipefail

# Convince the installer we are in CI
touch /.dockerenv

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Brew Install Script
curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install

rm -rf /home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/vendor
rm -rf /home/linuxbrew/.linuxbrew/Homebrew/.git
# Copy to image
cp -R /home/linuxbrew /usr/share/homebrew
