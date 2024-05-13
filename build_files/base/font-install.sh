#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" =~ "kinoite" ]]; then
    curl --output-dir /tmp -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    mkdir -p /usr/share/fonts/fira-nf
    unzip /tmp/FiraCode.zip -d /usr/share/fonts/fira-nf
    fc-cache -f /usr/share/fonts/fira-nf
fi

fc-cache -f /usr/share/fonts/ubuntu 
fc-cache -f /usr/share/fonts/inter
