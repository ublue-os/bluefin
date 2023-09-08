ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-37}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS bluefin

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="bluefin"

COPY usr /usr
COPY etc/yum.repos.d/ /etc/yum.repos.d/
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh

# gnome-vrr
RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo
RUN rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter mutter-common gnome-control-center gnome-control-center-filesystem xorg-x11-server-Xwayland
RUN rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo

## bootc
RUN wget https://copr.fedorainfracloud.org/coprs/rhcontainerbot/bootc/repo/fedora-"${FEDORA_MAJOR_VERSION}"/bootc-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/bootc.repo
RUN rpm-ostree install bootc
RUN rm -f /etc/yum.repos.d/bootc.repo

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    systemctl enable dconf-update.service && \
    fc-cache -f /usr/share/fonts/ubuntu && \
    fc-cache -f /usr/share/fonts/inter && \
    rm -f /etc/yum.repos.d/tailscale.repo && \
    rm -f /usr/share/applications/fish.desktop && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    sed -i '/^PRETTY_NAME/s/Silverblue/Bluefin/' /usr/lib/os-release && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

## bluefin-dx developer edition image section
FROM bluefin AS bluefin-dx

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="bluefin-dx"

# dx specific files come from the dx directory in this repo
COPY dx/usr /usr
COPY dx/etc/yum.repos.d/ /etc/yum.repos.d/
COPY workarounds.sh /tmp/workarounds.sh
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh

RUN wget https://copr.fedorainfracloud.org/coprs/ganto/lxc4/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo
RUN wget https://copr.fedorainfracloud.org/coprs/bobslept/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Handle packages via packages.json
RUN /tmp/build.sh

RUN wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
    install -c -m 0755 /tmp/docker-compose /usr/bin

COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/minio-client:latest /usr/bin/mc /usr/bin/mc
COPY --from=cgr.dev/chainguard/kubectl:latest /usr/bin/kubectl /usr/bin/kubectl

RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
RUN chmod +x ./kind
RUN mv ./kind /usr/bin/kind

# Install DevPod
RUN rpm-ostree install $(curl https://api.github.com/repos/loft-sh/devpod/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.rpm$")).browser_download_url') && \
  wget https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64 -O /tmp/devpod && \
  install -c -m 0755 /tmp/devpod /usr/bin

# Install kns/kctx and add completions for Bash
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/bin/kubectx && \
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/bin/kubens && \
    chmod +x /usr/bin/kubectx /usr/bin/kubens

    

RUN systemctl enable podman.socket
RUN systemctl disable pmie.service
RUN systemctl disable pmlogger.service

RUN /tmp/workarounds.sh

# Clean up repos, everything is on the image so we don't need them
RUN rm -f /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo
RUN rm -f /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo
RUN rm -f /etc/yum.repos.d/vscode.repo
RUN rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo
RUN rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo

RUN rm -rf /tmp/* /var/*
RUN ostree container commit

# Image for Framework laptops
FROM bluefin AS bluefin-framework

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="bluefin-framework"

COPY framework/usr /usr
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh

# Handle packages via packages.json
RUN /tmp/build.sh

RUN systemctl enable tlp
RUN systemctl enable fprintd.service

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
