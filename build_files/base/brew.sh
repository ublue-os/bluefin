#!/usr/bin/bash

set -xeou pipefail

# Convince the installer we are in CI
if [[ ! -f /.dockerenv ]]; then
    touch /.dockerenv
fi

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Install brew
/usr/libexec/brew-install

# Copy to image and own by UID 1000
cp -R /home/linuxbrew /usr/share/homebrew
