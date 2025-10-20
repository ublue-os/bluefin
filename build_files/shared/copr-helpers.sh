#!/usr/bin/bash
set -euo pipefail

copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    dnf5 -y copr enable "$copr_name"
    dnf5 -y copr disable "$copr_name"
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"

    echo "Installed ${packages[*]} from $copr_name"
}

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
