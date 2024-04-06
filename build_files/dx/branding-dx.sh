#!/usr/bin/bash

if [ "$BASE_IMAGE_NAME" = "silverblue" ]; then
    sed -i '/^PRETTY_NAME/s/Bluefin/Bluefin-dx/' /usr/lib/os-release
elif [ "$BASE_IMAGE_NAME" = "kinoite" ]; then
    sed -i '/^PRETTY_NAME/s/Aurora/Aurora-dx/' /usr/lib/os-release
fi