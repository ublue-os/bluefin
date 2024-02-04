#!/usr/bin/env bash

set -oue pipefail

# Make Directory
mkdir -p /usr/etc/containers/systemd/users

# bluefin-cli
wget --output-document="/usr/etc/containers/systemd/users/bluefin-cli.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/bluefin-cli/bluefin-cli.container 
printf "\n\n[Install]\nWantedBy=bluefin-cli.target" >> /usr/etc/containers/systemd/users/bluefin-cli.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/bluefin-cli.container
sed -i 's/ContainerName=bluefin/ContainerName=bluefin-cli/' /usr/etc/containers/systemd/users/bluefin-cli.container

# bluefin-dx-cli
wget --output-document="/usr/etc/containers/systemd/users/bluefin-dx-cli.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/bluefin-cli/bluefin-dx-cli.container 
printf "\n\n[Install]\nWantedBy=bluefin-dx-cli.target" >> /usr/etc/containers/systemd/users/bluefin-dx-cli.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/bluefin-dx-cli.container
sed -i 's/ContainerName=bluefin/ContainerName=bluefin-dx-cli/' /usr/etc/containers/systemd/users/bluefin-dx-cli.container

# fedora-toolbox
wget --output-document="/usr/etc/containers/systemd/users/fedora-toolbox.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/fedora-toolbox/fedora-distrobox-quadlet.container 
printf "\n\n[Install]\nWantedBy=fedora-toolbox.target" >> /usr/etc/containers/systemd/users/fedora-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/fedora-toolbox.container
sed -i 's/ContainerName=fedora-distrobox-quadlet/ContainerName=fedora-toolbox/' /usr/etc/containers/systemd/users/fedora-toolbox.container

# ubuntu-toolbox
wget --output-document="/usr/etc/containers/systemd/users/ubuntu-toolbox.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/ubuntu-toolbox/ubuntu-distrobox-quadlet.container 
printf "\n\n[Install]\nWantedBy=ubuntu-toolbox.target" >> /usr/etc/containers/systemd/users/ubuntu-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/ubuntu-toolbox.container
sed -i 's/ContainerName=ubuntu-distrobox-quadlet/ContainerName=ubuntu-toolbox/' /usr/etc/containers/systemd/users/ubuntu-toolbox.container

# wolfi-toolbox
wget --output-document="/usr/etc/containers/systemd/users/wolfi-toolbox.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/wolfi-toolbox/wolfi-distrobox-quadlet.container
printf "\n\n[Install]\nWantedBy=wolfi-toolbox.target" >> /usr/etc/containers/systemd/users/wolfi-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/wolfi-toolbox.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-toolbox/' /usr/etc/containers/systemd/users/wolfi-toolbox.container

# wolfi-dx-toolbox
wget --output-document="/usr/etc/containers/systemd/users/wolfi-dx-toolbox.container" --quiet https://raw.githubusercontent.com/ublue-os/toolboxes/main/quadlets/wolfi-toolbox/wolfi-dx-distrobox-quadlet.container
printf "\n\n[Install]\nWantedBy=wolfi-dx-toolbox.target" >> /usr/etc/containers/systemd/users/wolfi-dx-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/wolfi-dx-toolbox.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-dx-toolbox/' /usr/etc/containers/systemd/users/wolfi-dx-toolbox.container

# Make systemd targets and restart services for topgrade
mkdir -p /usr/lib/systemd/user
mkdir -p /usr/share/ublue-os/bluefin-cli
QUADLET_TARGETS=(
    "bluefin-cli"
    "bluefin-dx-cli"
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
cat > "/usr/lib/systemd/user/${i}-update.service" <<EOF
[Unit]
Description=Restart ${i}.service to rebuild container

[Service]
Type=oneshot
ExecStart=-/usr/bin/podman pull ghcr.io/ublue-os/${i}:latest
ExecStart=-/usr/bin/systemctl --user restart ${i}.service
EOF

cat > "/usr/share/ublue-os/bluefin-cli/${i}.sh" <<EOF
#!/bin/sh 
 
if test -n "\$PS1" && test ! -f "/run/.containerenv" && test ! -f "/run/user/\${UID}/container-entry" && test \$(podman ps --all --filter name=$i | grep -q " $i\$") ; then  
    touch "/run/user/\${UID}/container-entry"  
    exec /usr/bin/distrobox-enter $i 
fi
EOF
done
