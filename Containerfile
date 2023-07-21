ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"
ARG TARGET_BASE="${TARGET_BASE:-os}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS os

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY etc /etc
COPY usr /usr

COPY --from=cgr.dev/chainguard/cosign:latest /usr/bin/cosign /usr/bin/cosign

RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo
RUN rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter gnome-control-center gnome-control-center-filesystem xorg-x11-server-Xwayland

ADD packages.json /tmp/packages.json
ADD build.sh /tmp/build.sh

# FIXME: figure out why lens and openlens fail to install
# RUN rpm-ostree install $(curl https://api.github.com/repos/MuhammedKalkan/OpenLens/releases/latest | jq -r '.assets[] | select(.name| test("^OpenLens.*x86_64.rpm$")).browser_download_url')

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl unmask dconf-update.service && \
    systemctl enable dconf-update.service && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    fc-cache -f /usr/share/fonts/inter && \
    fc-cache -f /usr/share/fonts/intelmono && \
    rm -f /usr/share/applications/fish.desktop && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    # Clean up repos, everything is on the image so we don't need them
    rm -f /etc/yum.repos.d/tailscale.repo && \
    rm -f /etc/yum.repos.d/terra.repo && \
    rm -f /etc/yum.repos.d/gh-cli.repo && \
    rm -f /etc/yum.repos.d/vscode.repo && \
    rm -f /etc/yum.repos.d/hashicorp.repo && \
    rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
    rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    rm -rf /tmp/* /var/* && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

COPY workarounds.sh /tmp/workarounds.sh

COPY --from=cgr.dev/chainguard/cosign:latest /usr/bin/cosign /usr/bin/cosign
COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/kubectl:latest /usr/bin/kubectl /usr/bin/kubectl
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi /usr/bin/pulumi

RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
RUN chmod +x ./kind
RUN mv ./kind /usr/bin/kind

RUN systemctl enable podman.socket

RUN /tmp/workarounds.sh

RUN rm -rf /tmp/* /var/*
RUN ostree container commit