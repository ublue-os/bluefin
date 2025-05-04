#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script tailscale privileged 1 || exit 0

set -xeuo pipefail

tailscale set --operator="$(getent passwd "$PKEXEC_UID" | cut -d: -f1)"
