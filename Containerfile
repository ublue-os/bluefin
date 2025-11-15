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

# Install Homebrew
RUN --mount=type=cache,dst=/var/cache/homebrew,uid=1000,gid=1000 \
    set -eoux pipefail && \
    useradd -u 1000 -m -s /bin/bash -c "Homebrew Build User" linuxbrew && \
    mkdir -p /var/home/linuxbrew/.linuxbrew && \
    chown -R 1000:1000 /var/home/linuxbrew && \
    mkdir -p /var/cache/homebrew /var/lib/homebrew && \
    chown -R 1000:1000 /var/cache/homebrew /var/lib/homebrew && \
    su - linuxbrew -c "bash -c ' \
        export NONINTERACTIVE=1 && \
        export HOMEBREW_BREW_GIT_REMOTE=https://github.com/Homebrew/brew && \
        export HOMEBREW_CORE_GIT_REMOTE=https://github.com/Homebrew/homebrew-core && \
        export HOMEBREW_NO_AUTO_UPDATE=1 && \
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash \
    '" && \
    su - linuxbrew -c "git config --global gc.auto 0" && \
    test -x /var/home/linuxbrew/.linuxbrew/bin/brew && \
    /var/home/linuxbrew/.linuxbrew/bin/brew --version && \
    test -d /var/home/linuxbrew/.linuxbrew/Homebrew && \
    userdel linuxbrew && \
    dnf clean all

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

RUN bootc container lint
