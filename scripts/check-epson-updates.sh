#!/usr/bin/env bash
###############################################################################
# check-epson-updates.sh — Check for Epson package updates (local + CI)
###############################################################################
# This script checks for new versions of Epson printer software packages and
# optionally updates the build script with the new URLs.
#
# It uses two data sources:
#   1. Epson Download Center REST API (download-center.epson.com/api/v1/modules/)
#      Returns JSON with version + download URL. Requires User-Agent header.
#   2. AUR RPC v5 API (aur.archlinux.org/rpc/v5/info)
#      Returns JSON with version. Stable, no anti-bot. Used as fallback oracle.
#
# The Epson Download Center and all Epson download domains are behind Akamai's
# CDN/WAF which aggressively blocks automated requests:
#   - Requires browser-like User-Agent header
#   - Rate-limits rapidly repeated requests
#   - May block datacenter IP ranges entirely
#
# Usage:
#   ./scripts/check-epson-updates.sh              # Check only (no changes)
#   ./scripts/check-epson-updates.sh --update      # Check and update build script
#   ./scripts/check-epson-updates.sh --json        # Output JSON (for CI)
#
# Dependencies: curl, jq (optional but recommended), sed
###############################################################################

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
BUILD_SCRIPT="build_files/20-epson.sh"
# Epson Download Center API — device_id that includes both escpr and utility
EPSON_API_BASE="https://download-center.epson.com/api/v1/modules/"
EPSON_DEVICE_ID="L3250 Series"
EPSON_OS="RPM"
EPSON_REGION="US"
EPSON_LANGUAGE="en"
# AUR RPC v5 — fallback version oracle
AUR_API="https://aur.archlinux.org/rpc/v5/info"
# Browser User-Agent to satisfy Akamai WAF
# IMPORTANT: Akamai blocks UAs containing "Mozilla" (including real browser UAs).
# Use a simple browser name instead (e.g. 'Firefox').
USER_AGENT="Firefox"
# ──────────────────────────────────────────────────────────────────────────

# Color output (disabled for CI / non-interactive)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

MODE="check"
for arg in "$@"; do
    case "${arg}" in
        --update) MODE="update" ;;
        --json)   MODE="json" ;;
        --help|-h)
            echo "Usage: $0 [--update|--json|--help]"
            echo "  (no args)   Check for updates (display only)"
            echo "  --update    Check and update ${BUILD_SCRIPT}"
            echo "  --json      Output results as JSON (for CI)"
            exit 0 ;;
    esac
done

# ── Parse current versions from build script ──────────────────────────────
get_current_versions() {
    local script
    script="$(< "${BUILD_SCRIPT}")"
    CURRENT_ESCPR_VERSION=$(echo "${script}" | grep -oP 'ESCPR_VERSION="\K[0-9.]+')
    CURRENT_UTILITY_VERSION=$(echo "${script}" | grep -oP 'UTILITY_VERSION="\K[0-9.]+')
}

# ── Query Epson Download Center API ───────────────────────────────────────
query_epson_api() {
    local url
    url="${EPSON_API_BASE}?device_id=$(printf '%s' "${EPSON_DEVICE_ID}" | sed 's/ /%20/g')&os=${EPSON_OS}&region=${EPSON_REGION}&language=${EPSON_LANGUAGE}"
    local response
    response=$(curl --silent --location --max-time 30 --connect-timeout 15 \
        --user-agent "${USER_AGENT}" \
        "${url}" 2>/dev/null) || true
    echo "${response}"
}

# ── Parse escpr info from Epson API JSON ──────────────────────────────────
parse_escpr_from_api() {
    local json="$1"
    if command -v jq &>/dev/null; then
        REMOTE_ESCPR_VERSION=$(echo "${json}" | jq -r '
            .items[]
            | select(.cti == "10001")
            | select(.url != null)
            | select(.url | test("escpr.*\\.src\\.rpm$"))
            | .version' 2>/dev/null | head -1)
        REMOTE_ESCPR_URL=$(echo "${json}" | jq -r '
            .items[]
            | select(.cti == "10001")
            | select(.url != null)
            | select(.url | test("escpr.*\\.src\\.rpm$"))
            | .url' 2>/dev/null | head -1)
    else
        REMOTE_ESCPR_VERSION=$(echo "${json}" | grep -oP '"cti":"10001"[^}]*"version":"[^"]*"' | grep -oP '"version":"\K[0-9.]+' | head -1) || true
        REMOTE_ESCPR_URL=$(echo "${json}" | grep -oP '"url":"https://[^"]*escpr[^"]*\.src\.rpm"' | grep -oP '"url":"\K[^"]+' | head -1) || true
    fi
}

# ── Parse utility info from Epson API JSON ────────────────────────────────
parse_utility_from_api() {
    local json="$1"
    if command -v jq &>/dev/null; then
        REMOTE_UTILITY_VERSION=$(echo "${json}" | jq -r '
            .items[]
            | select(.url != null)
            | select(.url | test("printer-utility.*\\.x86_64\\.rpm$"))
            | .version' 2>/dev/null | head -1)
        REMOTE_UTILITY_URL=$(echo "${json}" | jq -r '
            .items[]
            | select(.url != null)
            | select(.url | test("printer-utility.*\\.x86_64\\.rpm$"))
            | .url' 2>/dev/null | head -1)
    else
        REMOTE_UTILITY_VERSION=$(echo "${json}" | grep -oP '"url":"https://[^"]*printer-utility[^"]*\.x86_64\.rpm"[^}]*"version":"[^"]*"' | grep -oP '"version":"\K[0-9.]+' | head -1) || true
        REMOTE_UTILITY_URL=$(echo "${json}" | grep -oP '"url":"https://[^"]*printer-utility[^"]*\.x86_64\.rpm"' | grep -oP '"url":"\K[^"]+' | head -1) || true
    fi
}

# ── Query AUR RPC as fallback version oracle ──────────────────────────────
query_aur_versions() {
    local response
    response=$(curl --silent --location --max-time 15 \
        "${AUR_API}?arg[]=epson-inkjet-printer-escpr&arg[]=epson-printer-utility" 2>/dev/null) || true

    if [[ -z "${response}" ]]; then
        echo "  ${YELLOW}⚠ AUR API unreachable${NC}" >&2
        return 1
    fi

    if command -v jq &>/dev/null; then
        AUR_ESCPR_VERSION=$(echo "${response}" | jq -r '
            .results[]
            | select(.Name == "epson-inkjet-printer-escpr")
            | .Version' 2>/dev/null | sed 's/-[0-9]*$//')
        AUR_UTILITY_VERSION=$(echo "${response}" | jq -r '
            .results[]
            | select(.Name == "epson-printer-utility")
            | .Version' 2>/dev/null | sed 's/-[0-9]*$//')
    else
        AUR_ESCPR_VERSION=$(echo "${response}" | grep -oP '"Name":"epson-inkjet-printer-escpr"[^}]*"Version":"\K[^"]+' | sed 's/-[0-9]*$//') || true
        AUR_UTILITY_VERSION=$(echo "${response}" | grep -oP '"Name":"epson-printer-utility"[^}]*"Version":"\K[^"]+' | sed 's/-[0-9]*$//') || true
    fi
}

# ── Update the build script with new version/URL ─────────────────────────
update_build_script() {
    local new_escpr_version="$1" new_escpr_url="$2" new_utility_version="$3" new_utility_url="$4"
    if [[ -n "${new_escpr_version}" && -n "${new_escpr_url}" ]]; then
        sed -i "s|ESCPR_VERSION=\"[0-9.]*\"|ESCPR_VERSION=\"${new_escpr_version}\"|" "${BUILD_SCRIPT}"
        sed -i "s|ESCPR_SRPM_URL=\"[^\"]*\"|ESCPR_SRPM_URL=\"${new_escpr_url}\"|" "${BUILD_SCRIPT}"
    fi
    if [[ -n "${new_utility_version}" && -n "${new_utility_url}" ]]; then
        sed -i "s|UTILITY_VERSION=\"[0-9.]*\"|UTILITY_VERSION=\"${new_utility_version}\"|" "${BUILD_SCRIPT}"
        sed -i "s|UTILITY_RPM_URL=\"[^\"]*\"|UTILITY_RPM_URL=\"${new_utility_url}\"|" "${BUILD_SCRIPT}"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────

REMOTE_ESCPR_VERSION="" ; REMOTE_ESCPR_URL=""
REMOTE_UTILITY_VERSION="" ; REMOTE_UTILITY_URL=""
AUR_ESCPR_VERSION="" ; AUR_UTILITY_VERSION=""
ESCPR_CHANGED=false ; UTILITY_CHANGED=false
EPSON_API_OK=false

get_current_versions

if [[ "${MODE}" != "json" ]]; then
    echo -e "${BOLD}Epson Printer Software Update Checker${NC}"
    echo -e "Current versions:"
    echo -e "  escpr:   ${CURRENT_ESCPR_VERSION}"
    echo -e "  utility: ${CURRENT_UTILITY_VERSION}"
    echo ""
fi

if [[ "${MODE}" != "json" ]]; then
    echo -e "${BLUE}Querying Epson Download Center API...${NC}"
fi

API_JSON=$(query_epson_api)

if [[ -n "${API_JSON}" ]] && echo "${API_JSON}" | grep -q '"items"'; then
    EPSON_API_OK=true
    parse_escpr_from_api "${API_JSON}"
    parse_utility_from_api "${API_JSON}"
    if [[ "${MODE}" != "json" ]]; then
        echo -e "  ${GREEN}✓ API accessible${NC}"
        [[ -n "${REMOTE_ESCPR_VERSION}" ]] && echo -e "  escpr:   ${REMOTE_ESCPR_VERSION} → ${REMOTE_ESCPR_URL}"
        [[ -n "${REMOTE_UTILITY_VERSION}" ]] && echo -e "  utility: ${REMOTE_UTILITY_VERSION} → ${REMOTE_UTILITY_URL}"
    fi
else
    if [[ "${MODE}" != "json" ]]; then
        echo -e "  ${YELLOW}⚠ Epson API blocked or unreachable (Akamai WAF)${NC}"
        echo -e "  Falling back to AUR version oracle..."
    fi
fi

if [[ "${MODE}" != "json" ]]; then
    echo -e "${BLUE}Querying AUR RPC API...${NC}"
fi

if query_aur_versions; then
    if [[ "${MODE}" != "json" ]]; then
        echo -e "  ${GREEN}✓ AUR API accessible${NC}"
        [[ -n "${AUR_ESCPR_VERSION}" ]] && echo -e "  escpr:   ${AUR_ESCPR_VERSION} (AUR)"
        [[ -n "${AUR_UTILITY_VERSION}" ]] && echo -e "  utility: ${AUR_UTILITY_VERSION} (AUR)"
    fi
    [[ -z "${REMOTE_ESCPR_VERSION}" ]] && REMOTE_ESCPR_VERSION="${AUR_ESCPR_VERSION}"
    [[ -z "${REMOTE_UTILITY_VERSION}" ]] && REMOTE_UTILITY_VERSION="${AUR_UTILITY_VERSION}"
fi

echo ""

[[ -n "${REMOTE_ESCPR_VERSION}" && "${REMOTE_ESCPR_VERSION}" != "${CURRENT_ESCPR_VERSION}" ]] && ESCPR_CHANGED=true
[[ -n "${REMOTE_UTILITY_VERSION}" && "${REMOTE_UTILITY_VERSION}" != "${CURRENT_UTILITY_VERSION}" ]] && UTILITY_CHANGED=true

if [[ "${MODE}" == "json" ]]; then
    cat <<EOF
{
  "escpr": {
    "current_version": "${CURRENT_ESCPR_VERSION}",
    "remote_version": "${REMOTE_ESCPR_VERSION}",
    "remote_url": "${REMOTE_ESCPR_URL}",
    "changed": ${ESCPR_CHANGED},
    "url_available": $([ -n "${REMOTE_ESCPR_URL}" ] && echo true || echo false)
  },
  "utility": {
    "current_version": "${CURRENT_UTILITY_VERSION}",
    "remote_version": "${REMOTE_UTILITY_VERSION}",
    "remote_url": "${REMOTE_UTILITY_URL}",
    "changed": ${UTILITY_CHANGED},
    "url_available": $([ -n "${REMOTE_UTILITY_URL}" ] && echo true || echo false)
  },
  "epson_api_ok": ${EPSON_API_OK}
}
EOF
    exit 0
fi

if [[ "${ESCPR_CHANGED}" == "true" || "${UTILITY_CHANGED}" == "true" ]]; then
    echo -e "${BOLD}${YELLOW}Updates available:${NC}"
    echo ""
    if [[ "${ESCPR_CHANGED}" == "true" ]]; then
        echo -e "  ${BOLD}epson-inkjet-printer-escpr${NC}"
        echo -e "    Current: ${RED}${CURRENT_ESCPR_VERSION}${NC}"
        echo -e "    Latest:  ${GREEN}${REMOTE_ESCPR_VERSION}${NC}"
        if [[ -n "${REMOTE_ESCPR_URL}" ]]; then
            echo -e "    URL:     ${REMOTE_ESCPR_URL}"
        else
            echo -e "    URL:     ${YELLOW}Not available (Epson API blocked)${NC}"
            echo -e "             https://support.epson.net/linux/Printer/LSB_distribution_pages/en/escpr.php"
        fi
        echo ""
    fi
    if [[ "${UTILITY_CHANGED}" == "true" ]]; then
        echo -e "  ${BOLD}epson-printer-utility${NC}"
        echo -e "    Current: ${RED}${CURRENT_UTILITY_VERSION}${NC}"
        echo -e "    Latest:  ${GREEN}${REMOTE_UTILITY_VERSION}${NC}"
        if [[ -n "${REMOTE_UTILITY_URL}" ]]; then
            echo -e "    URL:     ${REMOTE_UTILITY_URL}"
        else
            echo -e "    URL:     ${YELLOW}Not available (Epson API blocked)${NC}"
            echo -e "             https://support.epson.net/linux/Printer/LSB_distribution_pages/en/utility.php"
        fi
        echo ""
    fi
    if [[ "${MODE}" == "update" ]]; then
        NEW_ESCPR_V="" ; NEW_ESCPR_U="" ; NEW_UTIL_V="" ; NEW_UTIL_U=""
        [[ "${ESCPR_CHANGED}" == "true" && -n "${REMOTE_ESCPR_URL}" ]] && NEW_ESCPR_V="${REMOTE_ESCPR_VERSION}" && NEW_ESCPR_U="${REMOTE_ESCPR_URL}"
        [[ "${UTILITY_CHANGED}" == "true" && -n "${REMOTE_UTILITY_URL}" ]] && NEW_UTIL_V="${REMOTE_UTILITY_VERSION}" && NEW_UTIL_U="${REMOTE_UTILITY_URL}"
        if [[ -n "${NEW_ESCPR_V}" || -n "${NEW_UTIL_V}" ]]; then
            update_build_script "${NEW_ESCPR_V}" "${NEW_ESCPR_U}" "${NEW_UTIL_V}" "${NEW_UTIL_U}"
            [[ -n "${NEW_ESCPR_V}" ]] && echo -e "${GREEN}✓ Updated escpr to ${NEW_ESCPR_V} in ${BUILD_SCRIPT}${NC}"
            [[ -n "${NEW_UTIL_V}" ]] && echo -e "${GREEN}✓ Updated utility to ${NEW_UTIL_V} in ${BUILD_SCRIPT}${NC}"
        fi
    else
        echo -e "Run with ${BOLD}--update${NC} to apply changes to ${BUILD_SCRIPT}"
    fi
else
    echo -e "${GREEN}Epson printer software is up to date.${NC}"
fi
