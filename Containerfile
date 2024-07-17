ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-${IMAGE_FLAVOR}}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"
ARG NVIDIA_TYPE="${NVIDIA_TYPE:-}"
ARG KERNEL="${KERNEL:-6.9.7-200.fc40.x86_64}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# FROM's for copying
ARG KMOD_SOURCE_COMMON="ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
ARG ZFS_CACHE="ghcr.io/ublue-os/akmods-zfs:coreos-stable-${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_CACHE="ghcr.io/ublue-os/akmods-nvidia:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
ARG KERNEL_CACHE="ghcr.io/ublue-os/${AKMODS_FLAVOR}-kernel:${KERNEL}"
FROM ${KMOD_SOURCE_COMMON} AS akmods
FROM ${ZFS_CACHE} AS zfs_cache
FROM ${NVIDIA_CACHE} AS nvidia_cache
FROM ${KERNEL_CACHE} AS kernel_cache

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_TYPE="${NVIDIA_TYPE:-}"
ARG KERNEL="${KERNEL:-6.9.7-200.fc40.x86_64}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# COPY Build Files
COPY build_files/base build_files/shared /tmp/build/
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /
COPY just /tmp/just
COPY packages.json /tmp/packages.json

# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY /system_files/shared/usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml
# COPY ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
# COPY --from=akmods /rpms /tmp/akmods-rpms
# COPY --from=nvidia_cache /rpms /tmp/akmods-rpms
# COPY --from=kernel_cache /tmp/rpms /tmp/kernel-rpms

# Build, cleanup, commit.
RUN --mount=type=bind,from=akmods,source=/rpms,target=/tmp/akmods \
    --mount=type=bind,from=nvidia_cache,source=/rpms,target=/tmp/akmods-rpms \
    --mount=type=bind,from=kernel_cache,source=/tmp/rpms,target=/tmp/kernel-rpms \
    --mount=type=bind,from=zfs_cache,source=/rpms,target=/tmp/akmods-zfs \
    rpm-ostree cliwrap install-to-root / && \
    mkdir -p /var/lib/alternatives && \
    bash -c ". /tmp/build/build-base.sh"  && \
    mv /var/lib/alternatives /staged-alternatives && \
    rm -rf /tmp/* || true && \
    rm -rf /var/* || true && \
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
ARG NVIDIA_TYPE="${NVIDIA_TYPE:-}"
ARG KERNEL="${KERNEL:-6.9.7-200.fc40.x86_64}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-latest}"

# dx specific files come from the dx directory in this repo
COPY build_files/dx build_files/shared /tmp/build/
COPY system_files/dx /
COPY packages.json /tmp/packages.json

# Copy akmods from ublue
# COPY --from=akmods /rpms /tmp/akmods-rpms

# Build, Clean-up, Commit
RUN --mount=type=bind,from=akmods,source=/rpms,target=/tmp/akmods \
    mkdir -p /var/lib/alternatives && \
    bash -c ". /tmp/build/build-dx.sh"  && \
    fc-cache --system-only --really-force --verbose && \
    mv /var/lib/alternatives /staged-alternatives && \
    rm -rf /tmp/* || true && \
    rm -rf /var/* || true && \
    ostree container commit && \
    mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
