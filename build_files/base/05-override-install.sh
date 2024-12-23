#!/usr/bin/bash

set -eoux pipefail

# Patched shells
rpm-ostree override replace \
--experimental \
--from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    gnome-shell

# GNOME Triple Buffering
if [[ "${BASE_IMAGE_NAME}" =~ silverblue && "${FEDORA_MAJOR_VERSION}" -lt "41" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        mutter \
        mutter-common
fi

# Fix for ID in fwupd
rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        fwupd \
        fwupd-plugin-flashrom \
        fwupd-plugin-modem-manager \
        fwupd-plugin-uefi-capsule-data

# Switcheroo patch
rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control

rm /etc/yum.repos.d/_copr_sentry-switcheroo-control_discrete.repo

# Starship Shell Prompt
curl --retry 3 -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Topgrade Install
pip install --prefix=/usr topgrade

# Install ublue-update -- breaks with packages.json due to missing topgrade
rpm-ostree install ublue-update

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Move over ublue-update config
mv -f /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter
