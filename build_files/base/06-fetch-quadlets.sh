#!/usr/bin/env bash

set -ouex pipefail

# Make Directory
mkdir -p /etc/containers/systemd/users

# fedora-toolbox
curl --retry 3 -Lo /etc/containers/systemd/users/fedora-toolbox.container https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/fedora-toolbox/fedora-distrobox-quadlet.container
sed -i 's/ContainerName=fedora-distrobox-quadlet/ContainerName=fedora-toolbox/' /etc/containers/systemd/users/fedora-toolbox.container

# ubuntu-toolbox
curl --retry 3 -Lo /etc/containers/systemd/users/ubuntu-toolbox.container https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/ubuntu-toolbox/ubuntu-distrobox-quadlet.container
sed -i 's/ContainerName=ubuntu-distrobox-quadlet/ContainerName=ubuntu-toolbox/' /etc/containers/systemd/users/ubuntu-toolbox.container

# wolfi-toolbox
curl --retry 3 -Lo /etc/containers/systemd/users/wolfi-toolbox.container https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/wolfi-toolbox/wolfi-distrobox-quadlet.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-toolbox/' /etc/containers/systemd/users/wolfi-toolbox.container

# wolfi-dx-toolbox
curl --retry 3 -Lo /etc/containers/systemd/users/wolfi-dx-toolbox.container https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/wolfi-toolbox/wolfi-dx-distrobox-quadlet.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-dx-toolbox/' /etc/containers/systemd/users/wolfi-dx-toolbox.container

# Brew Integration for Fedora and Ubuntu Toolboxes
printf "\nVolume=/home/linuxbrew:/home/linuxbrew:rslave\nVolume=/etc/profile.d/brew.sh:/etc/profile.d/brew.sh:ro\nVolume=/usr/share/fish/vendor_conf.d/brew.fish:/usr/share/fish/vendor_conf.d/brew.fish:ro\n" >> /etc/containers/systemd/users/ubuntu-toolbox.container
printf "\nVolume=/home/linuxbrew:/home/linuxbrew:rslave\nVolume=/etc/profile.d/brew.sh:/etc/profile.d/brew.sh:ro\nVolume=/usr/share/fish/vendor_conf.d/brew.fish:/usr/share/fish/vendor_conf.d/brew.fish:ro\n" >> /etc/containers/systemd/users/fedora-toolbox.container

# Make systemd targets
mkdir -p /usr/lib/systemd/user
QUADLET_TARGETS=(
    "fedora-toolbox"
    "ubuntu-toolbox"
    "wolfi-toolbox"
    "wolfi-dx-toolbox"
)
for i in "${QUADLET_TARGETS[@]}"
do
cat > "/usr/lib/systemd/user/${i}.target" <<EOF
[Unit]
Description=${i}"target for ${i} quadlet

[Install]
WantedBy=default.target
EOF

# Add ptyxis integration and have autostart tied to systemd targets
cat /usr/share/ublue-os/bluefin-cli/ptyxis-integration >> /etc/containers/systemd/users/"$i".container
printf "\n\n[Install]\nWantedBy=%s.target" "$i" >> /etc/containers/systemd/users/"$i".container
done
