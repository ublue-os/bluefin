ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-${IMAGE_FLAVOR}}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"

# KMODs
ARG KMOD_SOURCE_COMMON="ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
FROM ${KMOD_SOURCE_COMMON} as akmods

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
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/share/bash-prexec /usr/share/bash-prexec
# COPY ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
COPY --from=akmods /rpms /tmp/akmods-rpms

# Build, cleanup, commit.
RUN rpm-ostree cliwrap install-to-root / && \
    mkdir -p /tmp/mediatek-firmware && \
    curl -Lo /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin?inline=false && \
    curl -Lo /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_RAM_CODE_MT7922_1.bin?inline=false && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin && \
    mv -vf /tmp/mediatek-firmware/* /usr/lib/firmware/mediatek/ && \
    rm -rf /tmp/mediatek-firmware && \
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
