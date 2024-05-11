#!/usr/bin/bash

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/brew.sh
chmod +x /tmp/brew.sh
ln -s /usr/lib/homebrew /var/home
env CLI=1 NONINTERACTIVE=1 /tmp/brew.sh 