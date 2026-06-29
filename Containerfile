# Produces: lbssousa/bluefin and lbssousa/bluefin-dx
# Layers Epson printer support on top of the official Bluefin images.
#
# Build args:
#   BASE_IMAGE  — full image name (ghcr.io/ublue-os/bluefin or bluefin-dx)
#   BASE_TAG    — image tag (default: stable)
#   BASE_DIGEST — sha256 digest (pinned by image-versions.yml + Renovate)

# renovate: datasource=docker depName=ghcr.io/ublue-os/bluefin
ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin"
ARG BASE_TAG="stable"
ARG BASE_DIGEST="sha256:9f0201d21641133b15c5e58e6cf85008259e8ffce1c7169a063f7474f2f56c41"

FROM scratch AS ctx
COPY build_files /build_files
COPY cosign.pub /cosign.pub

FROM ${BASE_IMAGE}:${BASE_TAG}@${BASE_DIGEST}

ARG IMAGE_NAME="bluefin"
ARG IMAGE_TAG="stable"

ENV IMAGE_NAME=${IMAGE_NAME}
ENV IMAGE_TAG=${IMAGE_TAG}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/00-signing.sh && \
    /ctx/build_files/05-gnome-extensions.sh && \
    /ctx/build_files/20-epson.sh && \
    /ctx/build_files/30-u2f.sh && \
    /ctx/build_files/40-goodix-fingerprint.sh

RUN bootc container lint
