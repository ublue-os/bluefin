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

# ChairLift (Control Center): the GUI comes from the ublue-os/tap chairlift
# cask, which brew-preinstall installs at login and brew-upgrade keeps current. A
# cask cannot install root-owned files, so the image ships the pkexec helper,
# its PolicyKit policy and the GSettings schemas from the same release. The
# release's checksums.txt is checked against its Sigstore bundle (signed by
# ChairLift's release workflow for exactly this tag) and the archive against
# checksums.txt, so a bump only changes CHAIRLIFT_RELEASE. Same steps as
# projectbluefin/common's Containerfile.
FROM ghcr.io/sigstore/cosign/cosign:v3.1.4@sha256:0f06154836d2de34f887a5c273506d52ca43edaa1d9e53e6510fa78a48f69c2d AS cosign
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_SHA} AS chairlift
ARG CHAIRLIFT_RELEASE=v26.11.8
ARG TARGETARCH
COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign
RUN set -eu; \
    case "${TARGETARCH}" in \
      amd64|arm64) ;; \
      *) echo "no ChairLift release archive for TARGETARCH '${TARGETARCH}'" >&2; exit 1 ;; \
    esac; \
    version="${CHAIRLIFT_RELEASE#v}"; \
    archive="chairlift_${version}_linux_${TARGETARCH}.tar.gz"; \
    install -d /tmp/chairlift-release; \
    cd /tmp/chairlift-release; \
    for asset in checksums.txt checksums.txt.sigstore.json "$archive"; do \
      curl --fail --silent --show-error --location --retry 5 --retry-all-errors --retry-delay 2 \
        --output "$asset" \
        "https://github.com/projectbluefin/chairlift/releases/download/${CHAIRLIFT_RELEASE}/${asset}"; \
    done; \
    # cosign keeps its TUF cache under $HOME; /root is a dangling symlink here.
    HOME=/tmp/chairlift-release cosign verify-blob --bundle checksums.txt.sigstore.json \
      --certificate-identity "https://github.com/projectbluefin/chairlift/.github/workflows/release.yml@refs/tags/${CHAIRLIFT_RELEASE}" \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      checksums.txt; \
    awk -v archive="$archive" 'NF == 2 && $2 == archive' checksums.txt > "$archive.sha256"; \
    if [ "$(wc -l < "$archive.sha256")" -ne 1 ]; then \
      echo "checksums.txt has no single entry for $archive" >&2; exit 1; \
    fi; \
    sha256sum -c "$archive.sha256"; \
    install -d /tmp/chairlift; \
    tar -xzf "$archive" -C /tmp/chairlift \
      chairlift-helper \
      data/io.projectbluefin.chairlift.ublue.policy \
      data/io.projectbluefin.chairlift.livery.gschema.xml \
      data/io.projectbluefin.chairlift.updates.gschema.xml \
      data/io.projectbluefin.chairlift.firstrun.gschema.xml \
      data/io.projectbluefin.chairlift.printers.gschema.xml; \
    policy=/tmp/chairlift/data/io.projectbluefin.chairlift.ublue.policy; \
    grep -qF '<annotate key="org.freedesktop.policykit.exec.path">/usr/bin/chairlift-helper</annotate>' "$policy"; \
    if grep -F 'org.freedesktop.policykit.exec.path' "$policy" | grep -vqF '>/usr/bin/chairlift-helper<'; then \
      echo "ChairLift policy authorizes a helper other than /usr/bin/chairlift-helper" >&2; exit 1; \
    fi; \
    install -Dm0755 /tmp/chairlift/chairlift-helper /out/usr/bin/chairlift-helper; \
    install -Dm0644 "$policy" /out/usr/share/polkit-1/actions/io.projectbluefin.chairlift.ublue.policy; \
    for schema in livery updates firstrun printers; do \
      install -Dm0644 "/tmp/chairlift/data/io.projectbluefin.chairlift.${schema}.gschema.xml" \
        "/out/usr/share/glib-2.0/schemas/io.projectbluefin.chairlift.${schema}.gschema.xml"; \
    done; \
    rm -rf /tmp/chairlift /tmp/chairlift-release

FROM scratch AS ctx
COPY /build_files /build_files
COPY --from=wallpapers /out /system_files/shared
COPY --from=chairlift /out /system_files/shared
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
