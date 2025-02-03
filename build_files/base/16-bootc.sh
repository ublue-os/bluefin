#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

if [ "$FEDORA_MAJOR_VERSION" -eq "40" ]; then
    /usr/bin/bootupctl backend generate-update-metadata
fi

echo "::endgroup::"
