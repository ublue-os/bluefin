#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Install Epson Printer Software from Epson's website
###############################################################################
# Installs two packages obtained directly from Epson's Linux download portal:
#
# 1. epson-inkjet-printer-escpr - Epson Inkjet Printer Driver (ESC/P-R) for Linux
#    Source: https://support.epson.net/linux/Printer/LSB_distribution_pages/en/escpr.php
#    Built from Epson's source RPM to ensure compatibility with modern Fedora.
#
# 2. epson-printer-utility - Epson Printer Utility for Linux
#    Source: https://support.epson.net/linux/Printer/LSB_distribution_pages/en/utility.php
#    Installed from Epson's binary RPM package.
#
# Version update:
#   - CI: `.github/workflows/check-epson-updates.yml` (Epson API + AUR fallback)
#   - Local: `./scripts/check-epson-updates.sh --update`
#
# Downloads require a real browser name as User-Agent (e.g. 'Firefox') to pass
# Akamai CDN/WAF. Generic strings like 'Mozilla' or 'curl' are blocked.
# See AUR PKGBUILD: https://aur.archlinux.org/packages/epson-inkjet-printer-escpr
###############################################################################

# ── Pinned versions & URLs ────────────────────────────────────────────────
# Primary: download-center.epson.com (latest versions, requires browser UA)
# Fallback: download3.ebz.epson.net (AkamaiNetStorage CDN, no UA check, older versions)

# renovate: datasource=custom.epson-escpr
ESCPR_VERSION="1.8.8"
ESCPR_SRPM_URL="https://download-center.epson.com/f/module/e934c1f6-0fc1-43e5-8d3e-0de8f3a3d357/epson-inkjet-printer-escpr-${ESCPR_VERSION}-1.src.rpm"
ESCPR_FALLBACK_VERSION="1.8.6"
ESCPR_FALLBACK_URL="https://download3.ebz.epson.net/dsc/f/03/00/16/21/79/6d53e6ec3f8c1e55733eb7860e992a425883bf88/epson-inkjet-printer-escpr-${ESCPR_FALLBACK_VERSION}-1.src.rpm"

# renovate: datasource=custom.epson-printer-utility
UTILITY_VERSION="1.2.2"
UTILITY_RPM_URL="https://download-center.epson.com/f/module/0fd7dd73-92c2-451e-88cf-cf385e0f6db7/epson-printer-utility-${UTILITY_VERSION}-1.x86_64.rpm"
UTILITY_FALLBACK_VERSION="1.1.3"
UTILITY_FALLBACK_URL="https://download3.ebz.epson.net/dsc/f/03/00/15/43/24/e0c56348985648be318592edd35955672826bf2c/epson-printer-utility-${UTILITY_FALLBACK_VERSION}-1.x86_64.rpm"

# ── Download helper ───────────────────────────────────────────────────────
# Tries the primary URL (download-center.epson.com) with a browser-like
# User-Agent, then falls back to the direct CDN URL (download3.ebz.epson.net)
# which has no anti-bot restrictions but may carry an older version.
download_epson() {
    local output="$1" primary_url="$2" fallback_url="$3" desc="$4"

    echo "Downloading ${desc}..."
    if curl -L --fail --retry 3 --retry-delay 5 -A 'Firefox' \
            --output "${output}" "${primary_url}"; then
        return 0
    fi

    echo "WARN: Primary download failed (Akamai may be blocking this IP)."
    echo "WARN: Falling back to CDN URL (may be an older version)."
    if curl -L --fail --retry 3 --retry-delay 5 \
            --output "${output}" "${fallback_url}"; then
        return 0
    fi

    echo "ERROR: All download sources failed for ${desc}!"
    echo "  Primary:  ${primary_url}"
    echo "  Fallback: ${fallback_url}"
    echo "Try running locally: ./scripts/check-epson-updates.sh"
    return 1
}
# ──────────────────────────────────────────────────────────────────────────

echo "::group:: Install Build Dependencies for ESC/P-R Driver"

dnf5 install -y \
    autoconf \
    automake \
    cups-devel \
    gcc \
    libtool \
    rpm-build

echo "::endgroup::"

echo "::group:: Install Runtime Dependencies"

dnf5 install -y \
    cups \
    cups-filters \
    ghostscript

echo "::endgroup::"

echo "::group:: Build and Install epson-inkjet-printer-escpr ${ESCPR_VERSION}"

ESCPR_BUILD_DIR=$(mktemp -d)
trap 'rm -rf "${ESCPR_BUILD_DIR}"' EXIT

download_epson \
    "${ESCPR_BUILD_DIR}/epson-inkjet-printer-escpr.src.rpm" \
    "${ESCPR_SRPM_URL}" \
    "${ESCPR_FALLBACK_URL}" \
    "epson-inkjet-printer-escpr src.rpm"

pushd "${ESCPR_BUILD_DIR}"
  rpm2cpio epson-inkjet-printer-escpr.src.rpm | cpio -idmv

  # Detect actual version from extracted tarball (may differ if fallback was used)
  ESCPR_TARBALL=$(ls epson-inkjet-printer-escpr-*-1.tar.gz)
  ESCPR_ACTUAL_VERSION=$(echo "${ESCPR_TARBALL}" | sed 's/epson-inkjet-printer-escpr-\(.*\)-1\.tar\.gz/\1/')
  echo "Building epson-inkjet-printer-escpr version: ${ESCPR_ACTUAL_VERSION}"

  tar xzf "${ESCPR_TARBALL}"
  cd "epson-inkjet-printer-escpr-${ESCPR_ACTUAL_VERSION}"

  autoreconf -vif
  # GCC 14 (Fedora 41+) promotes -Wimplicit-function-declaration to an error;
  # the Epson source predates this strictness. Suppress only that warning to
  # keep the rest of -Wall active.
  CFLAGS="${CFLAGS:--O2} -Wno-implicit-function-declaration" \
  ./configure \
      --prefix=/usr \
      --with-cupsfilterdir=/usr/lib/cups/filter \
      --with-cupsppddir=/usr/share/ppd
  make
  make install
popd

echo "::endgroup::"

echo "::group:: Install epson-printer-utility ${UTILITY_VERSION}"

UTILITY_RPM="${ESCPR_BUILD_DIR}/epson-printer-utility.x86_64.rpm"

download_epson \
    "${UTILITY_RPM}" \
    "${UTILITY_RPM_URL}" \
    "${UTILITY_FALLBACK_URL}" \
    "epson-printer-utility RPM"

# Install the binary RPM:
# --nodeps   : skip dependency checks (LSB compatibility shim not present on modern Fedora)
# --nodigest : skip payload-digest verification; RPM 4.19+ (Fedora 40+) rejects
#              packages built without a SHA-256 payload digest header, which
#              applies to this older Epson binary RPM
rpm -i --nodeps --nodigest "${UTILITY_RPM}"

echo "::endgroup::"

echo "::group:: Enable Services"

# Enable the Epson Connect Billing Daemon used by epson-printer-utility
systemctl enable ecbd.service || true

echo "::endgroup::"

echo "::group:: Cleanup device nodes"

# Device nodes (e.g. /dev/ecblp0) created by the epson-printer-utility RPM
# post-install scriptlet cannot be stored in OCI image layers; they must be
# created at runtime by udev. Remove them here to avoid rechunking failures.
# Use -xdev to stay within the root filesystem (avoiding bind/tmpfs mounts),
# and target all special file types that bootc/rpm-ostree cannot process.
find / -xdev \( -type c -o -type b -o -type p -o -type s \) -name 'ecblp*' -delete 2>/dev/null || true

echo "::endgroup::"

echo "::group:: Cleanup Build Dependencies"

dnf5 remove -y \
    autoconf \
    automake \
    libtool \
    rpm-build

# Remove the Epson source/binary archives (build dir is cleaned by trap)
trap - EXIT
rm -rf "${ESCPR_BUILD_DIR}"

echo "::endgroup::"

echo "Epson printer software installation complete!"
