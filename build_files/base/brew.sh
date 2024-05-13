#!/usr/bin/bash

set -xeou pipefail

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/brew.sh
chmod +x /tmp/brew.sh

# Convince the installer we are in CI
if [[ ! -f /.dockerenv ]]; then
    touch /.dockerenv
fi

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Install brew, Get portable Ruby
/tmp/brew.sh
/home/linuxbrew/.linuxbrew/bin/brew update

# Copy to image and own by UID 1000
cp -R /home/linuxbrew /usr/share/homebrew
chown -R 1000:1000 /usr/share/homebrew