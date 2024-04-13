#!/usr/bin/bash
# shellcheck disable=SC1091

set -oue pipefail

. /tmp/build/copr-repos.sh
. /tmp/build/nvidia-explicit-sync.sh
. /tmp/build/install-akmods.sh
. /tmp/build/packages.sh
. /tmp/build/fetch-install.sh
. /tmp/build/image-info.sh
. /tmp/build/fetch-quadlets.sh
. /tmp/build/font-install.sh
. /tmp/build/install-tmp.sh
. /tmp/build/systemd.sh
. /tmp/build/aurora-changes.sh
. /tmp/build/branding.sh
. /tmp/build/initramfs.sh
. /tmp/build/cleanup.sh