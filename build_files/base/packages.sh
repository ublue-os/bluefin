#!/usr/bin/bash

set -ouex pipefail

# build list of all packages requested for inclusion
INCLUDED_PACKAGES=($(jq -r "[(.all.include.all[]), \
                    (.\"$FEDORA_MAJOR_VERSION\".include.all[]), \
                    (.all.include.$BASE_IMAGE_NAME[]), \
                    (.\"$FEDORA_MAJOR_VERSION\".include.$BASE_IMAGE_NAME[])] \
                    | sort | unique[]" /tmp/packages.json))

# build list of all packages requested for exclusion
EXCLUDED_PACKAGES=($(jq -r "[(.all.exclude.all[]), \
                    (.\"$FEDORA_MAJOR_VERSION\".exclude.all[]), \
                    (.all.exclude.$BASE_IMAGE_NAME[]), \
                    (.\"$FEDORA_MAJOR_VERSION\".exclude.$BASE_IMAGE_NAME[])] \
                    | sort | unique[]" /tmp/packages.json))

# ensure exclusion list only contains packages already present on image
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

# simple case to install where no packages need excluding
if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
    rpm-ostree install \
        ${INCLUDED_PACKAGES[@]}

# install/excluded packages both at same time
elif [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]} \
        $(printf -- "--install=%s " ${INCLUDED_PACKAGES[@]})
else
    echo "No packages to install."
fi

# check if any excluded packages are still present
# (this can happen if an included package pulls in a dependency)
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

# remove any excluded packages which are still present on image
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]}
fi
