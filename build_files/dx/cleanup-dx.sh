#!/usr/bin/bash

set -ouex pipefail

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/karmab-kcli-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/atim-ubuntu-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/docker-ce.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

for i in /etc/yum.repos.d/rpmfusion-*; do
    sed -i 's@enabled=1@enabled=0@g' "$i"
done
