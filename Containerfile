ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-latest}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS builder

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY etc /etc

COPY --from=docker.io/bketelsen/fleek:latest /app/fleek /usr/bin/fleek
COPY --from=docker.io/bketelsen/fleek:latest /en/man1/fleek.1.gz /usr/share/man/man1/fleek.1.gz
COPY --from=docker.io/bketelsen/fleek:latest /pt/man1/fleek.1.gz /usr/share/man/pt/man1/fleek.1.gz
COPY --from=docker.io/bketelsen/fleek:latest /completions/fleek.bash /etc/bash_completion.d/fleek
COPY --from=docker.io/bketelsen/fleek:latest /completions/fleek.zsh /usr/local/share/zsh/site-functions/_fleek


ADD packages.json /tmp/packages.json
ADD build.sh /tmp/build.sh

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl unmask dconf-update.service && \
    systemctl enable dconf-update.service && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl disable NetworkManager-wait-online.service && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts -O /etc/hosts && \
    grubby --args "zswap.enabled=1 mitigations=off nowatchdog processor.ignore_ppc=1 amdgpu.ppfeaturemask=0xffffffff ec_sys.write_support=1" --update-kernel=ALL && \
    echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level && \
    echo high > /sys/class/drm/card1/device/power_dpm_force_performance_level && \
    echo kernel.kptr_restrict=1 > /etc/sysctl.d/51-kptr-restrict.conf && \
    echo 'blacklist sp5100_tco' > /etc/modprobe.d/disable-sp5100-watchdog.conf && \
    modprobe tcp_bbr && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
