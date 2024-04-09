ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-aurora-dx}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"
ARG TARGET_BASE="${TARGET_BASE:-lutho}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS lutho-dx

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="lutho"

COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh
COPY image-info.sh /tmp/image-info.sh

RUN /tmp/build.sh
RUN /tmp/image-info.sh
# RUN sed -i '/^PRETTY_NAME/s/Aurora/Lutho/' /usr/lib/os-release
RUN rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

# install userspace tablet driver
RUN wget https://github.com/OpenTabletDriver/OpenTabletDriver/releases/latest/download/OpenTabletDriver.rpm -O /tmp/opentabletdriver.rpm && \
    rpm-ostree install /tmp/opentabletdriver.rpm && \
    rm -rf /tmp/*
    # note: the user needs to manually enable the systemctl service according to https://opentabletdriver.net/Wiki/FAQ/Linux#autostart
