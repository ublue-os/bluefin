#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Goodix 538d fingerprint reader support (libfprint goodixtls53xd + SIGFM)
###############################################################################
# The stock libfprint has no driver for the Goodix 27c6:538d sensor (found in
# e.g. several Dell Inspiron/Vostro laptops). This builds and installs a
# patched libfprint that adds the goodixtls53xd driver: a real TLS-PSK capture
# backend plus SIGFM (SIFT/OpenCV) matching, since the default minutiae matcher
# performs poorly on this tiny 64x80 press sensor.
#
# Source: https://github.com/lbssousa/libfprint (tag below), based on upstream
# libfprint 1.94.10. Hardware-validated (enroll + verify) on a 27c6:538d.
#
# This replaces the base image's /usr libfprint in-place. OpenCV is pulled as a
# normal runtime dependency (no bundling needed inside the image, unlike a
# /usr/local install on an immutable host). When the base image bumps
# libfprint, this script simply rebuilds on top at the next image build.
###############################################################################

echo "::group:: ===$(basename "$0")==="

# renovate: datasource=github-tags depName=lbssousa/libfprint
LIBFPRINT_TAG="v1.94.10-goodix538d"
LIBFPRINT_REPO="https://github.com/lbssousa/libfprint"

# Runtime dependency of the SIGFM matcher (stays in the final image).
dnf5 -y install opencv

# Build-time only dependencies. pkg-config is intentionally NOT listed: the
# base image already ships it (kmod depends on it), so removing it would break
# the dnf transaction.
BUILD_DEPS=(
    meson ninja-build gcc gcc-c++ git-core
    glib2-devel libgusb-devel libgudev-devel nss-devel pixman-devel cairo-devel
    gobject-introspection-devel systemd-devel openssl-devel opencv-devel
    python3-gobject gtk-doc
)
dnf5 -y install "${BUILD_DEPS[@]}"

git clone --depth 1 --branch "$LIBFPRINT_TAG" "$LIBFPRINT_REPO" /tmp/libfprint

meson setup /tmp/libfprint/build /tmp/libfprint \
    --prefix=/usr --libdir=lib64 --buildtype=release \
    -Ddoc=false -Dgtk-examples=false -Dintrospection=true -Dinstalled-tests=false
ninja -C /tmp/libfprint/build
# Overwrites the base image's libfprint in /usr (driver superset of stock).
ninja -C /tmp/libfprint/build install

rm -rf /tmp/libfprint
# Revert exactly the build-deps install transaction above. This removes the
# toolchain and the -devel packages it pulled in, while leaving the runtime
# `opencv` (installed in a separate, earlier transaction) and any pre-existing
# base packages (e.g. pkg-config) untouched — avoiding dependency conflicts.
dnf5 -y history undo last || true
dnf5 -y clean all

echo "::endgroup::"
