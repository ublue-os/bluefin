#!/usr/bin/env bash

set -xeuo pipefail

# Copy ISO list for `install-system-flaptaks`
install -Dm0644 -t /etc/ublue-os/ "${CONTEXT_PATH}"/flatpaks/*.list

# Copy Files to Container
install -Dm0644 -t "/usr/share/ublue-os/homebrew" "${CONTEXT_PATH}"/brew/*.Brewfile

# Consolidate Just Files
find "${CONTEXT_PATH}/just" -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just
