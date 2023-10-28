ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"
ARG TARGET_BASE="${TARGET_BASE:-bluefin}"

## bluefin image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS bluefin

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="bluefin"

# GNOME VRR
RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo && \
    if [ ${FEDORA_MAJOR_VERSION} -lt 39 ]; then \
        rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter mutter-common gnome-control-center gnome-control-center-filesystem xorg-x11-server-Xwayland \
    ; else \
        rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter mutter-common gnome-control-center gnome-control-center-filesystem \
    ; fi && \
    rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo

COPY usr /usr
COPY just /tmp/just
COPY etc/yum.repos.d/ /etc/yum.repos.d/
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh
COPY image-info.sh /tmp/image-info.sh
# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml

# Add ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
COPY --from=ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION} /rpms /tmp/akmods-rpms
RUN sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    wget https://negativo17.org/repos/fedora-multimedia.repo -O /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then \
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
            /tmp/akmods-rpms/kmods/*xpad-noone*.rpm \
            /tmp/akmods-rpms/kmods/*xone*.rpm \
            /tmp/akmods-rpms/kmods/*openrazer*.rpm \
            /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
            /tmp/akmods-rpms/kmods/*wl*.rpm \
    ; else \
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*evdi*.rpm \
    ; fi && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    mkdir -p /etc/akmods-rpms/ && \
    mv /tmp/akmods-rpms/kmods/*steamdeck*.rpm /etc/akmods-rpms/steamdeck.rpm

# Starship Shell Prompt
RUN curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" && \
  tar -xzf /tmp/starship.tar.gz -C /tmp && \
  install -c -m 0755 /tmp/starship /usr/bin && \
  echo 'eval "$(starship init bash)"' >> /etc/bashrc

RUN wget https://copr.fedorainfracloud.org/coprs/ublue-os/bling/repo/fedora-$(rpm -E %fedora)/ublue-os-bling-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_ublue-os-bling.repo && \
    wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    /tmp/build.sh && \
    /tmp/image-info.sh && \
    pip install --prefix=/usr yafti && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d && \
    cp /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    systemctl enable dconf-update.service && \
    systemctl enable ublue-update.timer && \
    systemctl enable ublue-system-setup.service && \
    systemctl enable ublue-system-flatpak-manager.service && \
    systemctl --global enable ublue-user-flatpak-manager.service && \
    systemctl --global enable ublue-user-setup.service && \
    fc-cache -f /usr/share/fonts/ubuntu && \
    fc-cache -f /usr/share/fonts/inter && \
    find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just && \
    rm -f /etc/yum.repos.d/tailscale.repo && \
    rm -f /etc/yum.repos.d/_copr_ublue-os-bling.repo && \
    rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
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

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="bluefin-dx"

# dx specific files come from the dx directory in this repo
COPY dx/usr /usr
COPY dx/etc/yum.repos.d/ /etc/yum.repos.d/
COPY workarounds.sh \
     packages.json \
     build.sh \
     image-info.sh \
    /tmp

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
RUN sysctl -p

RUN wget https://copr.fedorainfracloud.org/coprs/ganto/lxc4/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Handle packages via packages.json
RUN /tmp/build.sh && \
    /tmp/image-info.sh

RUN wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
    install -c -m 0755 /tmp/docker-compose /usr/bin

COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/minio-client:latest /usr/bin/mc /usr/bin/mc
COPY --from=cgr.dev/chainguard/kubectl:latest /usr/bin/kubectl /usr/bin/kubectl

RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind

# Install DevPod
RUN rpm-ostree install https://github.com/loft-sh/devpod/releases/download/v0.3.7/DevPod_linux_x86_64.rpm && \
    wget https://github.com/loft-sh/devpod/releases/download/v0.3.7/devpod-linux-amd64 -O /tmp/devpod && \
    install -c -m 0755 /tmp/devpod /usr/bin

# Install kns/kctx and add completions for Bash
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/bin/kubectx && \
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/bin/kubens && \
    chmod +x /usr/bin/kubectx /usr/bin/kubens

# Install Charm VHS & dependencies
RUN rpm-ostree install $(curl https://api.github.com/repos/charmbracelet/vhs/releases/latest | jq -r '.assets[] | select(.name| test(".*.x86_64.rpm$")).browser_download_url') && \
    wget https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -O /tmp/ttyd && \
    install -c -m 0755 /tmp/ttyd /usr/bin/ttyd

# Install Charm gum 
RUN rpm-ostree install $(curl https://api.github.com/repos/charmbracelet/gum/releases/latest | jq -r '.assets[] | select(.name| test(".*.x86_64.rpm$")).browser_download_url') 

# Set up services
RUN systemctl enable podman.socket && \
    systemctl disable pmie.service && \
    systemctl disable pmlogger.service

RUN /tmp/workarounds.sh

# Clean up repos, everything is on the image so we don't need them
RUN rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rm -f /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rm -f /etc/yum.repos.d/vscode.repo && \
    rm -f /etc/yum.repos.d/docker-ce.repo && \
    rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
    rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm -rf /tmp/* /var/* && \
    ostree container commit
