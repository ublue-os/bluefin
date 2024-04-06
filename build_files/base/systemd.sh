#!/usr/bin/bash


if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then \
    systemctl enable tuned.service \
; fi
systemctl enable rpm-ostree-countme.service
systemctl enable tailscaled.service
systemctl enable dconf-update.service
systemctl --global enable ublue-flatpak-manager.service
systemctl enable ublue-update.timer
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service