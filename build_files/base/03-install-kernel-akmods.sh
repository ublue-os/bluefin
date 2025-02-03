#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
do
    rpm --erase $pkg --nodeps
done

# Fetch Kernel
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/"${AKMODS_FLAVOR}"-kernel:"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/kernel-rpms
KERNEL_TARGZ=$(jq -r '.layers[].digest' < /tmp/kernel-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/kernel-rpms/"$KERNEL_TARGZ" -C /
mv /tmp/rpms/* /tmp/kernel-rpms/

# Install Kernel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm

# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Fetch Common AKMODS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Everyone
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
dnf5 -y install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*xpadneo*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm \
    /tmp/akmods/kmods/*framework-laptop*.rpm

# RPMFUSION Dependent AKMODS
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
dnf5 -y install \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# Nvidia AKMODS
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    # Fetch Nvidia RPMs
    if [[ "${IMAGE_NAME}" =~ open ]]; then
        skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
    else
        skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
    fi
    NVIDIA_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-rpms/manifest.json | cut -d : -f 2)
    tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
    mv /tmp/rpms/* /tmp/akmods-rpms/

    # Install Nvidia RPMs
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/b3a3dbddf4af81cfbfa7526c1918c9b9f014f86b/nvidia-install.sh # Change when nvidia-install.sh updates
    chmod +x /tmp/nvidia-install.sh
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
fi

# ZFS for gts/stable
if [[ ${AKMODS_FLAVOR} =~ coreos ]]; then
    # Fetch ZFS RPMs
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-zfs:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-zfs
    ZFS_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-zfs/manifest.json | cut -d : -f 2)
    tar -xvzf /tmp/akmods-zfs/"$ZFS_TARGZ" -C /tmp/
    mv /tmp/rpms/* /tmp/akmods-zfs/

    # Declare ZFS RPMs
    ZFS_RPMS=(
        /tmp/akmods-zfs/kmods/zfs/kmod-zfs-"${KERNEL}"-*.rpm
        /tmp/akmods-zfs/kmods/zfs/libnvpair3-*.rpm
        /tmp/akmods-zfs/kmods/zfs/libuutil3-*.rpm
        /tmp/akmods-zfs/kmods/zfs/libzfs5-*.rpm
        /tmp/akmods-zfs/kmods/zfs/libzpool5-*.rpm
        /tmp/akmods-zfs/kmods/zfs/python3-pyzfs-*.rpm
        /tmp/akmods-zfs/kmods/zfs/zfs-*.rpm
        pv
    )

    # Install
    dnf5 -y install "${ZFS_RPMS[@]}"

    # Depmod and autoload
    depmod -a -v "${KERNEL}"
    echo "zfs" > /usr/lib/modules-load.d/zfs.conf
fi

echo "::endgroup::"
