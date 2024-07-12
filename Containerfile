ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-main}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"
ARG KERNEL="${KERNEL:-}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# Sources for akmods
ARG KMOD_SOURCE_COMMON="ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
ARG KMOD_SOURCE_NVIDIA="ghcr.io/ublue-os/akmods-nvidia:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"

# Fetch akmods
FROM ${KMOD_SOURCE_COMMON} AS akmods
FROM ${KMOD_SOURCE_NVIDIA} AS akmods_nvidia

# Fetch fsync kernel
FROM ghcr.io/ublue-os/fsync:latest AS fsync

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG KERNEL="${KERNEL:-}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# COPY Build Files
COPY build_files/base build_files/shared /tmp/build/
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /
COPY just /tmp/just
COPY packages.json /tmp/packages.json

# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY /system_files/shared/usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml

# Copy ublue kmods
COPY --from=akmods /rpms /tmp/akmods-rpms
COPY --from=akmods_nvidia /rpms /tmp/akmods-rpms

# Copy fsync kernel
COPY --from=fsync /tmp/rpms /tmp/fsync-rpms

# Build, cleanup, commit.
RUN rpm-ostree cliwrap install-to-root / && \
    mkdir -p /var/lib/alternatives && \
    bash -c ". /tmp/build/build-base.sh"  && \
    mv /var/lib/alternatives /staged-alternatives && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

## bluefin-dx developer edition image section
FROM base AS dx

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG KERNEL="${KERNEL:-}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# dx specific files come from the dx directory in this repo
COPY build_files/dx build_files/shared /tmp/build/
COPY system_files/dx /
COPY packages.json /tmp/packages.json

# Copy akmods from ublue
COPY --from=akmods /rpms /tmp/akmods-rpms

# Build, Clean-up, Commit
RUN mkdir -p /var/lib/alternatives && \
    bash -c ". /tmp/build/build-dx.sh"  && \
    fc-cache --system-only --really-force --verbose && \
    mv /var/lib/alternatives /staged-alternatives && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
