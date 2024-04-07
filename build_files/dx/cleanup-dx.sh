#!/usr/bin/bash

set -ouex pipefail

rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
rm -f /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo
rm -f /etc/yum.repos.d/karmab-kcli-fedora-"${FEDORA_MAJOR_VERSION}".repo
rm -f /etc/yum.repos.d/atim-ubuntu-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo
rm -f /etc/yum.repos.d/vscode.repo
rm -f /etc/yum.repos.d/docker-ce.repo
rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo
rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo