#!/bin/sh

set -eoux pipefail

# alternatives cannot create symlinks on its own during a container build
if [[ -f /usr/bin/ld.bfd ]]; then
    ln -sf /usr/bin/ld.bfd /etc/alternatives/ld && ln -sf /etc/alternatives/ld /usr/bin/ld
fi


## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin! 
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "41" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    rpm-ostree override replace https://bodhi.fedoraproject.org/updates/FEDORA-2024-dd2e9fb225    
#fi
