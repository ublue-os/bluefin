#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Goodix 538d fingerprint reader support (libfprint goodixtls53xd + SIGFM)
###############################################################################
# Replace the base image's stock libfprint with our COPR build, which adds the
# goodixtls53xd driver for the Goodix 27c6:538d sensor (real TLS-PSK capture +
# SIGFM/OpenCV matching). The COPR package has a higher EVR than Fedora's, so
# it wins; OpenCV (the SIGFM runtime dependency) is pulled in automatically.
#
# We *upgrade* rather than install: `dnf install <pkg>` is a no-op when the
# package is already present (it does not move to a newer EVR), whereas
# `upgrade` bumps the already-installed libfprint (and -devel/-tests, if
# present) to the COPR version. The COPR repo is enabled only for this one
# transaction and is not left enabled in the final image (same isolation idea
# as shared/copr-helpers.sh::copr_install_isolated, which uses `install` and so
# is not suitable for replacing a base package).
#
# COPR:   https://copr.fedorainfracloud.org/coprs/lbssousa/libfprint-goodix538d/
# Source: https://github.com/lbssousa/libfprint  (rpm/libfprint.spec)
###############################################################################

echo "::group:: ===$(basename "$0")==="

COPR_PROJECT="lbssousa/libfprint-goodix538d"
REPO_ID="copr:copr.fedorainfracloud.org:${COPR_PROJECT//\//:}"

dnf5 -y copr enable "$COPR_PROJECT"
dnf5 -y copr disable "$COPR_PROJECT"
dnf5 -y --enablerepo="$REPO_ID" upgrade 'libfprint*'

echo "::endgroup::"
