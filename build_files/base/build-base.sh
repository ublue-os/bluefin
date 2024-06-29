#!/usr/bin/bash
# shellcheck disable=SC1091

set -ouex pipefail

. /tmp/build/firmware.sh
. /tmp/build/coreos_kernel.sh
. /tmp/build/copr-repos.sh
. /tmp/build/install-akmods.sh
. /tmp/build/packages.sh
. /tmp/build/nvidia.sh
. /tmp/build/image-info.sh
. /tmp/build/fetch-install.sh
. /tmp/build/brew.sh
. /tmp/build/fetch-quadlets.sh
. /tmp/build/font-install.sh
. /tmp/build/systemd.sh
. /tmp/build/bluefin-changes.sh
. /tmp/build/aurora-changes.sh
. /tmp/build/branding.sh
. /tmp/build/initramfs.sh
. /tmp/build/bootc.sh
. /tmp/build/cleanup.sh
