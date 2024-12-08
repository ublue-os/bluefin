#!/usr/bin/bash

set -eoux pipefail

# Patched shells
if [[ "${BASE_IMAGE_NAME}" =~ silverblue ]]; then
    dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-shell gnome-shell
elif [[ "${BASE_IMAGE_NAME}" =~ kinoite ]]; then
    dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        kf6-kio-core kf6-kio-core
fi

# GNOME Triple Buffering
if [[ "${BASE_IMAGE_NAME}" =~ silverblue && "${FEDORA_MAJOR_VERSION}" -lt "41" ]]; then
    dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        mutter mutter
fi

# Fix for ID in fwupd
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        fwupd fwupd

# Switcheroo patch
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control switcheroo-control

dnf5 -y copr remove sentry/switcheroo-control_discrete

# Starship Shell Prompt
curl --retry 3 -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Bash Prexec
curl --retry 3 -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

# Topgrade Install
pip install --prefix=/usr topgrade

# Install ublue-update -- breaks with packages.json due to missing topgrade
dnf5 -y install ublue-update

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Move over ublue-update config
mv -f /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter
