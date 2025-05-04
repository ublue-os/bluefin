#!/usr/bin/env bash

set -x

dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:staging install -y \
  readymade-nightly

dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install -y \
  bluefin-readymade-config

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<< $IMAGE_INFO)"
IMAGE_FLAVOR="$(jq -c -r '."image-flavor"' <<< $IMAGE_INFO)"

OUTPUT_NAME="ghcr.io/ublue-os/bluefin"
if [ "$IMAGE_FLAVOR" != "main" ] ; then
  OUTPUT_NAME="${OUTPUT_NAME}-${IMAGE_FLAVOR}"
fi
KARGS=""
if [ "$IMAGE_FLAVOR" =~ nvidia ] ; then
  KARGS='bootc_kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]'
fi 

tee /etc/readymade.toml <<EOF
[install]
allowed_installtypes = ["wholedisk"]
copy_mode = "bootc"
bootc_imgref = "containers-storage:$OUTPUT_NAME:$IMAGE_TAG"
bootc_enforce_sigpolicy = true
bootc_args = ["--skip-fetch-check"]
$KARGS

[[bento]]
title = "page-welcome"
desc = "page-installation-welcome-desc"
link = "https://projectbluefin.io"
icon = "explore-symbolic"

[[bento]]
title = "page-installation-help"
desc = "page-installation-help-desc"
link = "https://universal-blue.discourse.group/c/bluefin/6"
icon = "chat-symbolic"

[[bento]]
title = "page-installation-contrib"
desc = "page-installation-contrib-desc"
link = "https://docs.projectbluefin.io"
icon = "applications-development-symbolic"

[distro]
name = "Bluefin"

[[postinstall]]
module = "Script"
EOF

rm -f /usr/share/applications/liveinst.desktop
sed -i '/NoDisplay=.*/d' /usr/share/applications/com.fyralabs.Readymade.desktop
cp -f /usr/share/applications/com.fyralabs.Readymade.desktop /etc/xdg/autostart

mkdir -p /usr/share/readymade/postinstall.d
tee /usr/share/readymade/postinstall.d/10-flatpaks.sh <<EOF
#!/usr/bin/bash
set -x
mkdir -p /ostree/deploy/default/var/lib
rsync -aWHA /run/host/var/lib/flatpak /ostree/deploy/default/var/lib
EOF
chmod +x /usr/share/readymade/postinstall.d/10-flatpaks.sh

tee /usr/share/readymade/postinstall.d/99-mok.sh <<"EOF"
#!/usr/bin/bash
set -x

ENROLLMENT_PASSWORD=universalblue
SECUREBOOT_KEY="/etc/pki/akmods/certs/akmods-ublue.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
	echo "EFI mode not detected. Skipping key enrollment."
	exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
	echo "Secure boot key not provided: $SECUREBOOT_KEY"
	exit 0
fi

# SYS_ID="(cat /sys/devices/virtual/dmi/id/product_name)"
# if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
# echo "Steam Deck hardware detected. Skipping key enrollment."
# exit 0
# fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
EOF
chmod +x /usr/share/readymade/postinstall.d/99-mok.sh

# Entirely remove everythign from the livesys configuration for GNOME
# This file isnt necessary for us considering how much setting up for
# Anaconda this does. Instead just inline whatever we actually need.
tee /usr/libexec/livesys/sessions.d/livesys-gnome <<"EOF" 
#!/bin/sh

if [ ! -d /var/lib/gnome-initial-setup ]; then
  # don't run gnome-initial-setup
  mkdir ~liveuser/.config
  : > ~liveuser/.config/gnome-initial-setup-done
fi
EOF
chmod +x /usr/libexec/livesys/sessions.d/livesys-gnome

# These are only here because we removed the handling from livesys-gnome

tee /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override <<EOF
[org.gnome.shell]
welcome-dialog-last-shown-version='4294967295'
favorite-apps = ['com.fyralabs.Readymade.desktop', 'documentation.desktop', 'discourse.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop']

[org.gnome.software]
allow-updates=false
download-updates=false
EOF

# don't autostart gnome-software session service
rm -f /etc/xdg/autostart/org.gnome.Software.desktop

# disable the gnome-software shell search provider
tee /usr/share/gnome-shell/search-providers/org.gnome.Software-search-provider.ini <<EOF
DefaultDisabled=true
EOF

tee /etc/gdm/custom.conf <<"EOF"
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl disable rpm-ostree-countme.service
systemctl disable tailscaled.service
systemctl disable bootloader-update.service
systemctl disable brew-upgrade.timer
systemctl disable brew-update.timer
systemctl disable brew-setup.service
systemctl disable rpm-ostree.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl disable ublue-guest-user.service
systemctl disable check-sb-key.service
systemctl --global disable ublue-flatpak-manager.service
systemctl --global disable podman-auto-update.timer
systemctl --global disable ublue-user-setup.service
