#!/usr/bin/bash
# shellcheck disable=SC1091

set -ouex pipefail

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
sysctl -p

cp /ctx/packages.json /tmp/packages.json
rsync -rvK /ctx/system_files/dx/ /

/ctx/build_files/copr-repos-dx.sh
/ctx/build_files/install-akmods-dx.sh
/ctx/build_files/packages-dx.sh
/ctx/build_files/image-info.sh
/ctx/build_files/fetch-install-dx.sh
/ctx/build_files/fonts-dx.sh
/ctx/build_files/workarounds.sh
/ctx/build_files/systemd-dx.sh
/ctx/build_files/branding-dx.sh
/ctx/build_files/cleanup-dx.sh
