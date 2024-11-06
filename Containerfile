ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="40"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY / /

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

# Build, cleanup, commit.
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/build-base.sh

## bluefin-dx developer edition image section
FROM base AS dx

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="40"
ARG IMAGE_NAME="bluefin-dx"
ARG IMAGE_VENDOR="ublue-os"
ARG KERNEL="6.10.10-200.fc40.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"

# Build, Clean-up, Commit
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/build-dx.sh
