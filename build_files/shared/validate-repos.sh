#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eou pipefail

REPOS_DIR="/etc/yum.repos.d"
VALIDATION_FAILED=0
ENABLED_REPOS=()

echo "Validating all repository files are disabled..."

# Check if repos directory exists
if [[ ! -d "$REPOS_DIR" ]]; then
    echo "Warning: $REPOS_DIR does not exist"
    exit 0
fi

# Function to check if a repo file has any enabled repos
check_repo_file() {
    local repo_file="$1"
    local basename_file
    basename_file=$(basename "$repo_file")

    # Skip if file doesn't exist or isn't readable
    [[ ! -f "$repo_file" ]] && return 0
    [[ ! -r "$repo_file" ]] && return 0

    # Check for enabled=1 in the file
    if grep -q "^enabled=1" "$repo_file" 2>/dev/null; then
        echo "ENABLED: $basename_file"
        ENABLED_REPOS+=("$basename_file")
        VALIDATION_FAILED=1

        # Show which sections are enabled
        echo "   Enabled sections:"
        local section_name=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                section_name="$line"
            elif [[ "$line" =~ ^enabled=1 ]]; then
                echo "     - $section_name"
            fi
        done < "$repo_file"
    else
        echo "Disabled: $basename_file"
    fi
}

echo ""
echo "Checking COPR repositories (standard naming)..."
echo "NOTE: With secure isolated installation, NO COPRs should be globally enabled!"
for repo in "$REPOS_DIR"/_copr:copr.fedorainfracloud.org:*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

echo ""
echo "Checking COPR repositories (non-standard naming)..."
echo "SECURITY: Enabled COPRs can inject malicious versions of Fedora packages!"
for repo in "$REPOS_DIR"/_copr_*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

echo ""
echo "Checking other third-party repositories..."
# List of known third-party repos that should be disabled
OTHER_REPOS=(
    "negativo17-fedora-multimedia.repo"
    "tailscale.repo"
    "vscode.repo"
    "docker-ce.repo"
    "fedora-cisco-openh264.repo"
    "fedora-coreos-pool.repo"
)

for repo_name in "${OTHER_REPOS[@]}"; do
    repo_path="$REPOS_DIR/$repo_name"
    if [[ -f "$repo_path" ]]; then
        check_repo_file "$repo_path"
    fi
done

echo ""
echo "Checking RPM Fusion repositories..."
for repo in "$REPOS_DIR"/rpmfusion-*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

echo ""
echo "Checking Fedora updates-testing (should be disabled unless beta)..."
if [[ -f "$REPOS_DIR/fedora-updates-testing.repo" ]]; then
    if grep -q "^enabled=1" "$REPOS_DIR/fedora-updates-testing.repo" 2>/dev/null; then
        # Allow updates-testing to be enabled for beta builds
        if [[ "${UBLUE_IMAGE_TAG:-stable}" == "beta" ]]; then
            echo "updates-testing is enabled (allowed for beta builds)"
        else
            echo "ENABLED: fedora-updates-testing.repo (should only be enabled for beta)"
            ENABLED_REPOS+=("fedora-updates-testing.repo")
            VALIDATION_FAILED=1
        fi
    else
        echo "Disabled: fedora-updates-testing.repo"
    fi
fi

# Final summary
echo ""
echo "======================================"
if [[ $VALIDATION_FAILED -eq 1 ]]; then
    echo "VALIDATION FAILED"
    echo "======================================"
    echo ""
    echo "The following repositories are still ENABLED:"
    for repo in "${ENABLED_REPOS[@]}"; do
        echo "  • $repo"
    done
    exit 1
fi

echo "::endgroup::"
