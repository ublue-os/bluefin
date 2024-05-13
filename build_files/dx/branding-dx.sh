#!/usr/bin/bash

set -ouex pipefail

if test "$BASE_IMAGE_NAME" = "silverblue"; then
    sed -i '/^PRETTY_NAME/s/Bluefin/Bluefin-dx/' /usr/lib/os-release
    sed -i 's/Bluefin/Bluefin-dx/' /usr/etc/yafti.yml
elif test "$BASE_IMAGE_NAME" = "kinoite"; then
    sed -i '/^PRETTY_NAME/s/Aurora/Aurora-dx/' /usr/lib/os-release
    sed -i 's/Aurora/Aurora-dx/' /usr/etc/yafti.yml
    sed -i 's/Aurora/Aurora-DX/' /usr/share/kde-settings/kde-profile/default/xdg/kcm-about-distrorc
fi
