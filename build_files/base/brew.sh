#!/usr/bin/bash

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/brew.sh
chmod +x /tmp/brew.sh
rm -f /home
env CLI=1 NONINTERACTIVE=1 /tmp/brew.sh
cp -R /home/linuxbrew/.linuxbrew /usr/lib/homebrew