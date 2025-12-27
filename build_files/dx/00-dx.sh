#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Load secure COPR helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# DX packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    android-tools
    bcc
    bpftop
    bpftrace
    cascadia-code-fonts
    cockpit-bridge
    cockpit-machines
    cockpit-networkmanager
    cockpit-ostree
    cockpit-podman
    cockpit-selinux
    cockpit-storaged
    cockpit-system
    dbus-x11
    edk2-ovmf
    flatpak-builder
    genisoimage
    git-subtree
    git-svn
    iotop
    libvirt
    libvirt-nss
    nicstat
    numactl
    osbuild-selinux
    p7zip
    p7zip-plugins
    podman-compose
    podman-machine
    podman-tui
    qemu
    qemu-char-spice
    qemu-device-display-virtio-gpu
    qemu-device-display-virtio-vga
    qemu-device-usb-redirect
    qemu-img
    qemu-system-x86-core
    qemu-user-binfmt
    qemu-user-static
    rocm-hip
    rocm-opencl
    rocm-smi
    sysprof
    incus
    incus-agent
    lxc
    tiptop
    trace-cmd
    udica
    util-linux-script
    virt-manager
    virt-v2v
    virt-viewer
    ydotool
)

echo "Installing ${#FEDORA_PACKAGES[@]} DX packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install --enablerepo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    docker-model-plugin

tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
dnf -y install --enablerepo=code \
    code


# DX packages to exclude - common to all versions
EXCLUDED_PACKAGES=()

# Version-specific package exclusions for DX
case "$FEDORA_MAJOR_VERSION" in
    43)
        EXCLUDED_PACKAGES+=(mozilla-fira-mono-fonts)
        ;;
esac

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service
systemctl enable bluefin-dx-groups.service

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Disable RPM Fusion repos
for i in /etc/yum.repos.d/rpmfusion-*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

echo "::endgroup::"
