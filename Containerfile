ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-${IMAGE_FLAVOR}}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"

# FROM's for copying
ARG KMOD_SOURCE_COMMON="ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
FROM ${KMOD_SOURCE_COMMON} as akmods
FROM ghcr.io/ublue-os/bluefin-cli as bluefin-cli

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

# COPY Build Files
COPY build_files/base build_files/shared /tmp/build/
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /
COPY just /tmp/just
COPY packages.json /tmp/packages.json

# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY /system_files/shared/usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml
# Copy Bluefin CLI packages
COPY --from=bluefin-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=bluefin-cli /usr/share/bash-prexec /usr/share/bash-prexec
# COPY ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
COPY --from=akmods /rpms /tmp/akmods-rpms

# Build, cleanup, commit.
RUN rpm-ostree cliwrap install-to-root / && \
    bash -c ". /tmp/build/build-base.sh"  && \
    rm -rf /tmp/* /var/* && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp && \
    ostree container commit

## bluefin-dx developer edition image section
FROM base AS dx

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

# dx specific files come from the dx directory in this repo
COPY build_files/dx build_files/shared /tmp/build/
COPY system_files/dx /
COPY packages.json /tmp/packages.json

# Copy akmods-extra from ublue
COPY --from=akmods /rpms /tmp/akmods-rpms

# Build, Clean-up, Commit
RUN bash -c ". /tmp/build/build-dx.sh"  && \
    fc-cache --system-only --really-force --verbose && \
    rm -rf /tmp/* /var/* && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp && \
    ostree container commit
