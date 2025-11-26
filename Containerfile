ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY /system_files /system_files
COPY /build_files /build_files
COPY /iso_files /iso_files
COPY /flatpaks /flatpaks
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:010a877426875af903b5135d53605337c0bac6c893e2ad3e203473824ae3675c /system_files /system_files/shared

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="40"
ARG IMAGE_NAME="bluefin"
ARG IMAGE_VENDOR="ublue-os"
ARG KERNEL="6.10.10-200.fc40.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG IMAGE_FLAVOR=""

# Build, cleanup, lint.
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/build_files/shared/build.sh

# Download Homebrew tarball (extracted at first boot by brew-setup.service)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=GITHUB_TOKEN \
    set -eoux pipefail && \
    ARCH=$(uname -m) && \
    # Get latest homebrew release tag from GitHub API
    HOMEBREW_RELEASE=$(curl -sL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/ublue-os/packages/releases" | \
        jq -r '[.[] | select(.tag_name | startswith("homebrew-"))][0].tag_name') && \
    echo "Using Homebrew release: ${HOMEBREW_RELEASE}" && \
    HOMEBREW_BASE_URL="https://github.com/ublue-os/packages/releases/download/${HOMEBREW_RELEASE}" && \
    # Download tarball to /usr/share 
    /ctx/build_files/shared/utils/ghcurl "${HOMEBREW_BASE_URL}/homebrew-${ARCH}.tar.zst" --retry 3 -o /usr/share/homebrew.tar.zst && \
    # Download and verify checksum
    EXPECTED_SHA=$(/ctx/build_files/shared/utils/ghcurl "${HOMEBREW_BASE_URL}/homebrew-${ARCH}.sha256" --retry 3 | awk '{print $1}') && \
    echo "${EXPECTED_SHA}  /usr/share/homebrew.tar.zst" | sha256sum -c && \
    # Verify tarball exists
    test -f /usr/share/homebrew.tar.zst

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

RUN bootc container lint
