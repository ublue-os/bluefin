#!/bin/sh

set -eoux pipefail

# alternatives cannot create symlinks on its own during a container build
if [[ -f /usr/bin/ld.bfd ]]; then
    ln -sf /usr/bin/ld.bfd /etc/alternatives/ld && ln -sf /etc/alternatives/ld /usr/bin/ld
fi


## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
if [ "$FEDORA_MAJOR_VERSION" -eq "41" ]; then
    rpm-ostree override replace https://bodhi.fedoraproject.org/updates/FEDORA-2024-dd2e9fb225    
fi
