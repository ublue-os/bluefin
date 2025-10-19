#!/usr/bin/bash
# Secure COPR helper functions
#
# These functions implement isolated COPR package installation to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
#
# Security model:
# 1. Enable COPR repo
# 2. Immediately disable COPR repo
# 3. Install package with --enablerepo flag (only that one command uses the COPR)
# 4. COPR cannot interfere with other package installations
#
# Usage:
#   source /ctx/build_files/shared/copr-helpers.sh
#   copr_install_isolated "che/nerd-fonts" "nerd-fonts"
#   copr_swap_isolated "ublue-os/staging" "fwupd" "fwupd"

set -euo pipefail

# Convert COPR short name to full repo ID
# Example: "che/nerd-fonts" → "copr:copr.fedorainfracloud.org:che:nerd-fonts"
copr_to_repoid() {
    local copr_name="$1"
    echo "copr:copr.fedorainfracloud.org:${copr_name//\//:}"
}

# Install package(s) from a COPR using isolated enablement
# This prevents the COPR from affecting other package installations
#
# Arguments:
#   $1: COPR name (e.g., "che/nerd-fonts")
#   $@: Package name(s) to install
#
# Example:
#   copr_install_isolated "che/nerd-fonts" "nerd-fonts"
#   copr_install_isolated "ublue-os/packages" "ublue-brew" "ublue-motd"
copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    local repo_id
    repo_id=$(copr_to_repoid "$copr_name")

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    dnf5 -y copr enable "$copr_name"
    dnf5 -y copr disable "$copr_name"
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"

    echo "Installed ${packages[*]} from $copr_name"
}

# Swap package(s) from a COPR using isolated enablement
# Used for replacing Fedora packages with patched versions from COPR
#
# Arguments:
#   $1: COPR name (e.g., "ublue-os/staging")
#   $@: Remaining arguments passed to dnf5 swap
#
# Example:
#   copr_swap_isolated "ublue-os/staging" "fwupd" "fwupd"
copr_swap_isolated() {
    local copr_name="$1"
    shift
    local swap_args=("$@")

    if [[ ${#swap_args[@]} -eq 0 ]]; then
        echo "ERROR: No swap arguments specified for copr_swap_isolated"
        return 1
    fi

    local repo_id
    repo_id=$(copr_to_repoid "$copr_name")

    echo "Swapping ${swap_args[*]} using COPR $copr_name (isolated)"

    dnf5 -y copr enable "$copr_name"
    dnf5 -y copr disable "$copr_name"
    dnf5 -y swap --enablerepo="$repo_id" "${swap_args[@]}"

    echo "Swapped using $copr_name"
}

# Install package(s) from a COPR with conditional error handling
# Useful for beta builds where packages might not exist yet
#
# Arguments:
#   $1: COPR name
#   $2: "optional" to allow failures, anything else to require success
#   $@: Package names
#
# Example:
#   copr_install_conditional "ublue-os/staging" "optional" "experimental-package"
copr_install_conditional() {
    local copr_name="$1"
    local mode="$2"
    shift 2
    local packages=("$@")

    if [[ "$mode" == "optional" ]]; then
        copr_install_isolated "$copr_name" "${packages[@]}" || {
            echo "Optional package installation failed: ${packages[*]}"
            return 0
        }
    else
        copr_install_isolated "$copr_name" "${packages[@]}"
    fi
}

# Install package from non-standard COPR repo (like akmods)
# For repos that don't follow standard COPR naming conventions
#
# Arguments:
#   $1: Full repo file path (e.g., "/etc/yum.repos.d/_copr_ublue-os-akmods.repo")
#   $2: Repo ID within the file (e.g., "copr:copr.fedorainfracloud.org:ublue-os:akmods")
#   $@: Package names or patterns
#
# Example:
#   copr_install_nonstandard "/etc/yum.repos.d/_copr_ublue-os-akmods.repo" \
#                            "copr:copr.fedorainfracloud.org:ublue-os:akmods" \
#                            "/tmp/akmods/kmods/*kvmfr*.rpm"
copr_install_nonstandard() {
    local repo_file="$1"
    local repo_id="$2"
    shift 2
    local packages=("$@")

    echo "Installing ${packages[*]} from non-standard repo (isolated)"

    sed -i 's@enabled=0@enabled=1@g' "$repo_file"
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"
    sed -i 's@enabled=1@enabled=0@g' "$repo_file"

    echo "Installed from non-standard repo"
}

# Install third-party repo and keep it disabled for isolated usage
# Used for non-COPR repos like Terra, Docker, VSCode, etc.
#
# Security model:
# 1. Install repo definition package(s)
# 2. Immediately disable the repo
# 3. Caller uses --repo= flag for specific commands only
#
# Arguments:
#   $1: Repo name (for logging)
#   $2: Repo URL for --repofrompath (use $releasever for version substitution)
#   $3: Release package name to install
#   $4: Optional extras package name (e.g., terra-release-extras)
#   $5: Optional glob pattern to disable (e.g., "terra*", defaults to exact repo name)
#
# Example:
#   thirdparty_repo_install "terra" \
#                           'terra,https://repos.fyralabs.com/terra$releasever' \
#                           "terra-release" \
#                           "terra-release-extras" \
#                           "terra*"
thirdparty_repo_install() {
    local repo_name="$1"
    local repo_frompath="$2"
    local release_package="$3"
    local extras_package="${4:-}"
    local disable_pattern="${5:-$repo_name}"

    echo "Installing $repo_name repo (isolated mode)"

    # Install the release package using temporary repo
    # shellcheck disable=SC2016
    dnf5 -y install --nogpgcheck --repofrompath "$repo_frompath" "$release_package"

    # Install extras package if specified (may not exist in all versions)
    if [[ -n "$extras_package" ]]; then
        dnf5 -y install "$extras_package" || true
    fi

    # Disable the repo(s) immediately
    dnf5 config-manager setopt "${disable_pattern}".enabled=0

    echo "$repo_name repo installed and disabled (ready for isolated usage)"
}

echo "COPR helper functions loaded (secure isolated installation mode)"
