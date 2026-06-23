#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# GNOME Shell Extension Fixes
###############################################################################
# The upstream Bluefin build (ublue-os/bluefin build-gnome-extensions.sh)
# compiles schemas for most bundled extensions, but custom-command-list
# (from projectbluefin/common, enabled in zz0-bluefin-modifications.gschema.override)
# is not listed there. Without gschemas.compiled in its schemas/ directory,
# GNOME Shell silently fails to enable the extension at login.
#
# This script plugs that gap by compiling the missing schema.
###############################################################################

echo "::group:: Compile custom-command-list GNOME extension schema"

EXTENSION_DIR="/usr/share/gnome-shell/extensions/custom-command-list@storageb.github.com"

if [[ -d "${EXTENSION_DIR}/schemas" ]]; then
    glib-compile-schemas --strict "${EXTENSION_DIR}/schemas"
    echo "custom-command-list schemas compiled successfully"
else
    echo "WARNING: ${EXTENSION_DIR}/schemas not found — skipping"
    echo "The extension may not be present in this base image version."
fi

echo "::endgroup::"
