#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Install pam-u2f for FIDO2/U2F authentication
###############################################################################
# The upstream Bluefin image ships libfido2 (udev rules) but not pam-u2f
# (the PAM module). Without pam_u2f.so, authselect's with-pam-u2f feature
# configures PAM stacks that reference a missing module, silently breaking
# FIDO2/U2F login and sudo.
###############################################################################

echo "::group:: Install pam-u2f"

dnf5 install -y pam-u2f

echo "::endgroup::"
