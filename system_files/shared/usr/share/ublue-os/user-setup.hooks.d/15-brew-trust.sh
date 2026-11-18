#!/usr/bin/env bash

# Homebrew 6+ refuses to load formulae and casks from taps the user has not
# trusted (https://docs.brew.sh/Tap-Trust). Trust is stored per user, so trust
# the taps that Bluefin's own Brewfiles and ujust recipes install from, once
# per user. `brew trust` only adds entries, so anything the user already
# trusted is kept, and because this runs once per version a later
# `brew untrust` by the user is respected. Third-party taps are left to the user.

source /usr/lib/ublue/setup-services/libsetup.sh

BREW="/home/linuxbrew/.linuxbrew/bin/brew"

# brew-setup.service may not have run yet; try again at the next login
if [[ ! -x "${BREW}" ]]; then
    echo "Homebrew not found at ${BREW}, skipping tap trust for now"
    exit 0
fi

version-script brew-trust user 1 || exit 0

set -x

TRUSTED_TAPS=(
    ublue-os/tap
    ublue-os/experimental-tap
)

# No network needed to record trust; keep brew from fetching API data
if ! HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_FROM_API=1 \
    "${BREW}" trust --tap "${TRUSTED_TAPS[@]}"; then
    # Forget the recorded version so this is retried at the next login
    tmp="$(mktemp)"
    jq 'del(.version.user."brew-trust")' "${SETUP_CHECKER_FILE}" >"${tmp}" && mv "${tmp}" "${SETUP_CHECKER_FILE}"
    exit 1
fi
