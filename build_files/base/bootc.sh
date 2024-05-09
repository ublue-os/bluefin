#!/usr/bin/bash

set -ouex pipefail

# Transforms /usr/lib/ostree-boot into a bootupd-compatible update payload
/usr/bin/bootupctl backend generate-update-metadata
