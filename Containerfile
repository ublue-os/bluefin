ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-37}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS builder

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY etc /etc
COPY usr /usr

COPY --from=docker.io/bketelsen/vanilla-os:v0.0.12 /usr/share/backgrounds/vanilla /usr/share/backgrounds/vanilla
COPY --from=docker.io/bketelsen/vanilla-os:v0.0.12 /usr/share/gnome-background-properties/vanilla.xml /usr/share/gnome-background-properties/vanilla.xml
COPY --from=docker.io/bketelsen/apx:latest /usr/bin/apx /usr/bin/apx
COPY --from=docker.io/bketelsen/apx:latest /etc/apx/config.json /etc/apx/config.json
COPY --from=docker.io/bketelsen/apx:latest /usr/share/apx /usr/share/apx

#RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo
#RUN rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter gnome-control-center gnome-control-center-filesystem

ADD packages.json /tmp/packages.json
ADD build.sh /tmp/build.sh

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl unmask dconf-update.service && \
    systemctl enable dconf-update.service && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    fc-cache -f /usr/share/fonts/ubuntu && \
    rm -f /etc/yum.repos.d/tailscale.repo && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

# K8s tools

COPY --from=cgr.dev/chainguard/kubectl:latest /usr/bin/kubectl /usr/bin/kubectl
COPY --from=cgr.dev/chainguard/cosign:latest /usr/bin/cosign /usr/bin/cosign

RUN curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.17.0/kind-$(uname)-amd64"
RUN chmod +x ./kind
RUN mv ./kind /usr/bin/kind

RUN semanage fcontext -a -t etc_t '/nix/store/[^/]+/etc(/.*)?'
RUN semanage fcontext -a -t lib_t '/nix/store/[^/]+/lib(/.*)?'
RUN semanage fcontext -a -t systemd_unit_file_t '/nix/store/[^/]+/lib/systemd/system(/.*)?'
RUN semanage fcontext -a -t man_t '/nix/store/[^/]+/man(/.*)?'
RUN semanage fcontext -a -t bin_t '/nix/store/[^/]+/s?bin(/.*)?'
RUN semanage fcontext -a -t usr_t '/nix/store/[^/]+/share(/.*)?'
RUN semanage fcontext -a -t var_run_t '/nix/var/nix/daemon-socket(/.*)?'
RUN semanage fcontext -a -t usr_t '/nix/var/nix/profiles(/per-user/[^/]+)?/[^/]+'

RUN mkdir -p /var/lib/nix

RUN semanage fcontext -a -t etc_t '/var/lib/nix/store/[^/]+/etc(/.*)?'
RUN semanage fcontext -a -t lib_t '/var/lib/nix/store/[^/]+/lib(/.*)?'
RUN semanage fcontext -a -t systemd_unit_file_t '/var/lib/nix/store/[^/]+/lib/systemd/system(/.*)?'
RUN semanage fcontext -a -t man_t '/var/lib/nix/store/[^/]+/man(/.*)?'
RUN semanage fcontext -a -t bin_t '/var/lib/nix/store/[^/]+/s?bin(/.*)?'
RUN semanage fcontext -a -t usr_t '/var/lib/nix/store/[^/]+/share(/.*)?'
RUN semanage fcontext -a -t var_run_t '/var/lib/nix/var/nix/daemon-socket(/.*)?'
RUN semanage fcontext -a -t usr_t '/var/lib/nix/var/nix/profiles(/per-user/[^/]+)?/[^/]+'

# Ensure systemd picks up the newly created units
RUN systemctl daemon-reload
# Enable the nix mount on boot.
RUN systemctl enable nix.mount
# Mount the nix mount now.
RUN systemctl start nix.mount
# R = recurse, F = full context (not just target)
RUN restorecon -RF /nix

RUN setenforce Permissive

RUN sh <(curl -L https://nixos.org/nix/install) --daemon

# Remove the linked services
sudo rm -f /etc/systemd/system/nix-daemon.{service,socket}
# Manually copy the services.
sudo cp /var/lib/nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.{service,socket} /etc/systemd/system/# R = recurse, F = full context (not just target)
RUN restorecon -RF /nix
# Ensure systemd picks up the newly created units
RUN systemctl daemon-reload
# Start (and enable) the nix-daemon socket
RUN systemctl enable --now nix-daemon.socket

RUN setenforce Enforcing