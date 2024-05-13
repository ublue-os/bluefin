#!/usr/bin/bash
set -euo pipefail

image=$1

if [[ ${image} =~ "bluefin" ]]; then
    echo silverblue
elif [[ ${image} =~ "aurora" ]]; then
    echo kinoite
else
    exit 1
fi
