#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# build list of all packages requested for inclusion
INCLUDED_PACKAGES=($(jq -r "[(.all.include | (select(.all != null).all)[]), \
                    (.all.include | (select(.\"$BASE_IMAGE_NAME\" != null).\"$BASE_IMAGE_NAME\")[]), \
                    (.all.include | (select(.dx != null).dx)[]), \
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (select(.all != null).all)[]), \
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (select(.\"$BASE_IMAGE_NAME\" != null).\"$BASE_IMAGE_NAME\")[]),
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (select(.dx != null).dx)[])] \
                    | sort | unique[]" /tmp/packages.json))

# build list of all packages requested for exclusion
EXCLUDED_PACKAGES=($(jq -r "[(.all.exclude | (select(.all != null).all)[]), \
                    (.all.exclude | (select(.\"$BASE_IMAGE_NAME\" != null).\"$BASE_IMAGE_NAME\")[]), \
                    (.all.exclude | (select(.dx != null).dx)[]), \
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".exclude | (select(.all != null).all)[]), \
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".exclude | (select(.\"$BASE_IMAGE_NAME\" != null).\"$BASE_IMAGE_NAME\")[]),
                    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".exclude | (select(.dx != null).dx)[])] \
                    | sort | unique[]" /tmp/packages.json))

# store a list of RPMs installed on the image
INSTALLED_EXCLUDED_PACKAGES=()

# ensure exclusion list only contains packages already present on image
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    INSTALLED_EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

# simple case to install where no packages need excluding
if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#INSTALLED_EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
    rpm-ostree install \
        ${INCLUDED_PACKAGES[@]}

# install/excluded packages both at same time
elif [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#INSTALLED_EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${INSTALLED_EXCLUDED_PACKAGES[@]} \
        $(printf -- "--install=%s " ${INCLUDED_PACKAGES[@]})
else
    echo "No packages to install."
fi

# check if any excluded packages are still present
# (this can happen if an included package pulls in a dependency)
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    INSTALLED_EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

# remove any excluded packages which are still present on image
if [[ "${#INSTALLED_EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${INSTALLED_EXCLUDED_PACKAGES[@]}
fi

echo "::endgroup::"
