#!/bin/sh

set -eoux pipefail

# alternatives cannot create symlinks on its own during a container build
if [[ -f /usr/bin/ld.bfd ]]; then
    ln -sf /usr/bin/ld.bfd /etc/alternatives/ld && ln -sf /etc/alternatives/ld /usr/bin/ld
fi
