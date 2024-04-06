#!/usr/bin/bash

set -oue pipefail

if test "$BASE_IMAGE_NAME" = "silverblue"; then
    sed -i '/^PRETTY_NAME/s/Silverblue/Bluefin/' /usr/lib/os-release
elif test "$BASE_IMAGE_NAME" = "kinoite"; then
    sed -i '/^PRETTY_NAME/s/Kinoite/Aurora/' /usr/lib/os-release
fi