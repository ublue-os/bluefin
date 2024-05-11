#!/usr/bin/bash

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/brew.sh
chmod +x /tmp/brew.sh
mkdir /var/home
ln -s /usr/lib/homebrew /var/home/linuxbrew
env CLI=1 NONINTERACTIVE=1 /tmp/brew.sh 