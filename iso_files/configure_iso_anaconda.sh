#!/usr/bin/env bash

set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<< $IMAGE_INFO)"
IMAGE_FLAVOR="$(jq -c -r '."image-flavor"' <<< $IMAGE_INFO)"
IMAGE_NAME="$(jq -c -r '."image-name"' <<< $IMAGE_INFO)"
IMAGE_REF="$(jq -c -r '."image-ref"' <<< $IMAGE_INFO)"
IMAGE_REF="${IMAGE_REF##*://}"
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Configure Live Environment

# Setup dock
tee /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override <<EOF
[org.gnome.shell]
welcome-dialog-last-shown-version='4294967295'
favorite-apps = ['liveinst.desktop', 'documentation.desktop', 'discourse.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop']

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

# Configure Anaconda

# Anaconda Profile Detection
# TODO: Make our own profiles to not need to do this
if [[ "$IMAGE_TAG" =~ lts ]]; then
    echo 'VARIANT_ID=silverblue' >>/usr/lib/os-release
else
    sed -i 's/^VARIANT_ID=.*/VARIANT_ID=silverblue/' /usr/lib/os-release
fi
sed -i 's/^ID=.*/ID=fedora/' /usr/lib/os-release

# Install Anaconda, Webui if >= F42
if [[ "$IMAGE_TAG" =~ lts ]]; then
    dnf install -y anaconda-liveinst
else
    SPECS=(
        "anaconda-live"
        "libblockdev-btrfs"
        "libblockdev-lvm"
        "libblockdev-dm"
    )
    if [[ "$(rpm -E %fedora)" -ge 42 ]]; then
        SPECS+=("anaconda-webui")
    fi
    dnf install -y "${SPECS[@]}"
fi

# Get Artwork
git clone --depth=1 https://github.com/ublue-os/packages.git /root/packages
mkdir -p /usr/share/anaconda/pixmaps/silverblue
cp -r /root/packages/bluefin/fedora-logos/src/anaconda/* /usr/share/anaconda/pixmaps/
cp -r /root/packages/bluefin/fedora-logos/src/anaconda/* /usr/share/anaconda/pixmaps/silverblue/
rm -rf /root/packages

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target"
%end
EOF

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/run/install/repo/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
	echo "EFI mode not detected. Skipping key enrollment."
	exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
	echo "Secure boot key not provided: $SECUREBOOT_KEY"
	exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
	echo "Steam Deck hardware detected. Skipping key enrollment."
	exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF