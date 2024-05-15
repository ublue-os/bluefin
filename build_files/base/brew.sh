#!/usr/bin/bash

set -xeou pipefail

# Convince the installer we are in CI
if [[ ! -f /.dockerenv ]]; then
    touch /.dockerenv
fi

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Install brew, Get portable Ruby
/usr/libexec/brew-install
/home/linuxbrew/.linuxbrew/bin/brew update

# Copy to image and own by UID 1000
cp -R /home/linuxbrew /usr/share/homebrew
chown -R 1000:1000 /usr/share/homebrew

# Remove update functions to prevent user
rm -f /usr/share/homebrew/.linuxbrew/Homebrew/Library/Homebrew/cmd/update.sh
rm -f /usr/share/homebrew/.linuxbrew/Homebrew/Library/Homebrew/cmd/update-reset.sh
