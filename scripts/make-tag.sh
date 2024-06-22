#!/usr/bin/bash
set -euo pipefail

image=$1
target=$2

# Add build to images to distinguish from ghcr
if [[ "${target}" =~ "base" ]]; then
    echo "${image}-build"
elif [[ "${target}" =~ "dx" ]]; then
    echo "${image}-${target}-build"
fi
