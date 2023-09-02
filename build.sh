#!/bin/sh

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

INCLUDED_PACKAGES=($(jq -r "[(.all.include | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[]), \
                             (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[])] \
                             | sort | unique[]" /tmp/packages.json))
EXCLUDED_PACKAGES=($(jq -r "[(.all.exclude | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[]), \
                             (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".exclude | (select(.\"$PACKAGE_LIST\" != null).\"$PACKAGE_LIST\")[])] \
                             | sort | unique[]" /tmp/packages.json))


if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
    rpm-ostree install \
        ${INCLUDED_PACKAGES[@]}

elif [[ "${#INCLUDED_PACKAGES[@]}" -eq 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]}

elif [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]} \
        $(printf -- "--install=%s " ${INCLUDED_PACKAGES[@]})

else
    echo "No packages to install."

fi
