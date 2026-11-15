ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG BASE_IMAGE_SHA=""
ARG WALLPAPERS_IMAGE="ghcr.io/ublue-os/bluefin-wallpapers-gnome:latest"
ARG WALLPAPERS_IMAGE_SHA=""
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG BREW_IMAGE_SHA=""

FROM ${WALLPAPERS_IMAGE}@${WALLPAPERS_IMAGE_SHA} AS wallpapers-src
FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew

# Wallpapers: same layout and path fix that projectbluefin/common applied
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_SHA} AS wallpapers
COPY --from=wallpapers-src / /out/usr/share
RUN mkdir -p /out/usr/share/backgrounds/bluefin && \
    mv /out/usr/share/*.jxl /out/usr/share/*.xml /out/usr/share/backgrounds/bluefin && \
    sed -i 's|~\/\.local\/share|\/usr\/share|' /out/usr/share/backgrounds/bluefin/*.xml /out/usr/share/gnome-background-properties/*.xml

FROM scratch AS ctx
COPY /build_files /build_files
COPY --from=wallpapers /out /system_files/shared
COPY --from=brew /system_files /system_files/shared
# bluefin-owned files overlay last so they take precedence
COPY /system_files /system_files

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_SHA} AS base

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

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

CMD ["/sbin/init"]

RUN bootc container lint
