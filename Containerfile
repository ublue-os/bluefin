ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-aurora}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-dx}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-${IMAGE_FLAVOR}}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-stable}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

COPY build.sh /tmp/build.sh
RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    mv /var/lib/alternatives /staged-alternatives && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
