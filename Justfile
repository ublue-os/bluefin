repo_organization := "ublue-os"
images := '(
    [aurora]=aurora
    [aurora-dx]=aurora-dx
    [bluefin]=bluefin
    [bluefin-dx]=bluefin-dx
)'
flavors := '(
    [main]=main
    [nvidia]=nvidia
    [hwe]=hwe
    [hwe-nvidia]=hwe-nvidia
)'
tags := '(
    [gts]=gts
    [stable]=stable
    [latest]=latest
    [beta]=beta
)'

[private]
default:
    @just --list

# Check Just Syntax
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json

# Sudo Clean
sudo-clean:
    #!/usr/bin/bash
    set -eoux pipefail
    just sudoif "find *_build* -exec rm -rf {} \;"
    just sudoif "rm -f previous.manifest.json"

# Check if valid combo
[private]
validate image="" tag="" flavor="":
    #!/usr/bin/bash
    set -eoux pipefail
    declare -A images={{ images }}
    declare -A tags={{ tags }}
    declare -A flavors={{ flavors }}
    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}
    checkimage="${images[${image}]-}"
    checktag="${tags[${tag}]-}"
    checkflavor="${flavors[${flavor}]-}"

    # Validity Checks
    if [[ -z "$checkimage" ]]; then
        echo "Invalid Image..."
        exit 1
    fi
    if [[ -z "$checktag" ]]; then
        echo "Invalid tag..."
        exit 1
    fi
    if [[ "$checktag" =~ gts && "$checkimage" =~ aurora ]]; then
        echo "Aurora Does not build GTS..."
        exit 1
    fi
    if [[ ! "$checktag" =~ latest && "$checkflavor" =~ hwe ]]; then
        echo "HWE images are only built on latest..."
        exit 1
    fi

# sudoif bash function
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# Build Image
build image="bluefin" tag="latest" flavor="main" rechunk="0":
    #!/usr/bin/bash
    set -eoux pipefail
    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    if [[ "${flavor}" =~ main ]]; then
        image_name="${image}"
    else
        image_name="${image}-${flavor}"
    fi

    # Base Image
    if [[ "${image}" =~ bluefin ]]; then
        base_image_name="silverblue"
    elif [[ "${image}" =~ aurora ]]; then
        base_image_name="kinoite"
    fi

    # Target
    if [[ "${image}" =~ dx ]]; then
        target="dx"
    else
        target="base"
    fi

    # Fedora Version
    if [[ "${tag}" =~ stable ]]; then
        fedora_version=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"]' | grep -oP 'fc\K[0-9]+')
    else
        fedora_version=$(skopeo inspect docker://ghcr.io/ublue-os/base-main:"${tag}" | jq -r '.Labels["ostree.linux"]' | grep -oP 'fc\K[0-9]+')
    fi

    # AKMODS Flavor and Kernel Version
    if [[ "${flavor}" =~ hwe ]]; then
        akmods_flavor="bazzite"
    elif [[ "${tag}" =~ stable|gts ]]; then
        akmods_flavor="coreos-stable"
    elif [[ "${tag}" =~ beta ]]; then
        akmods_flavor="coreos-testing"
    else
        akmods_flavor="main"
    fi
    kernel_release=$(skopeo inspect docker://ghcr.io/ublue-os/${akmods_flavor}-kernel:"${fedora_version}" | jq -r '.Labels["ostree.linux"]')

    # Get Version
    ver=$(skopeo inspect docker://ghcr.io/ublue-os/"${base_image_name}-main":"${fedora_version}" | jq -r '.Labels["org.opencontainers.image.version"]')
    if [ -z "$ver" ] || [ "null" = "$ver" ]; then
        echo "inspected image version must not be empty or null"
        exit 1
    fi

    # Build Arguments
    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "AKMODS_FLAVOR=${akmods_flavor}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE_NAME=${base_image_name}")
    BUILD_ARGS+=("--build-arg" "FEDORA_MAJOR_VERSION=${fedora_version}")
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR={{ repo_organization }}")
    BUILD_ARGS+=("--build-arg" "KERNEL=${kernel_release}")
    if ! git diff-index --quiet HEAD -- ; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi
    BUILD_ARGS+=("--build-arg" "UBLUE_IMAGE_TAG=${tag}")

    # Labels
    LABELS=()
    LABELS+=("--label" "org.opencontainers.image.title=${image_name}")
    LABELS+=("--label" "org.opencontainers.image.version=${ver}")
    LABELS+=("--label" "ostree.linux=${kernel_release}")
    LABELS+=("--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/bluefin/bluefin/README.md")
    LABELS+=("--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4")
    LABELS+=("--label" "org.opencontainers.image.description=An interpretation of the Ubuntu spirit built on Fedora technology")

    # Build Image
    podman build \
        "${BUILD_ARGS[@]}" \
        "${LABELS[@]}" \
        --target "${target}" \
        --tag "${image_name}:${tag}" \
        .

    # Rechunk
    if [[ "{{ rechunk }}" == "1" ]]; then
        just rechunk "${image}" "${tag}" "${flavor}"
    fi

# Build Image and Rechunk
build-rechunk image="bluefin" tag="latest" flavor="main":
    @just build {{ image }} {{ tag }} {{ flavor }} 1

# Rechunk Image
[private]
rechunk image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail

    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    if [[ "${flavor}" =~ main ]]; then
        image_name="${image}"
    else
        image_name="${image}-${flavor}"
    fi

    # Check if image is already built
    ID=$(podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        just build "${image}" "${tag}" "${flavor}"
    fi

    # Load into Rootful Podman
    ID=$(just sudoif podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        just sudoif podman image scp ${UID}@localhost::localhost/"${image_name}":"${tag}" root@localhost::localhost/"${image_name}":"${tag}"
    fi

    # Prep Container
    CREF=$(just sudoif podman create localhost/"${image_name}":"${tag}" bash)
    MOUNT=$(just sudoif podman mount "${CREF}")
    OUT_NAME="${image_name}_build"

    # Run Rechunker's Prune
    just sudoif podman run --rm \
        --pull=newer \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        ghcr.io/hhd-dev/rechunk:latest \
        /sources/rechunk/1_prune.sh

    # Run Rechunker's Create
    just sudoif podman run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --volume "cache_ostree:/var/ostree" \
        --env TREE=/var/tree \
        --env REPO=/var/ostree/repo \
        --env RESET_TIMESTAMP=1 \
        --user 0:0 \
        ghcr.io/hhd-dev/rechunk:latest \
        /sources/rechunk/2_create.sh

    # Cleanup Temp Container Reference
    just sudoif podman unmount "$CREF"
    just sudoif podman rm "$CREF"

    # Run Rechunker
    just sudoif podman run --rm \
        --pull=newer \
        --security-opt label=disable \
        --volume "$PWD:/workspace" \
        --volume "$PWD:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF=ghcr.io/ublue-os/"${image_name}":"${tag}" \
        --env OUT_NAME="$OUT_NAME" \
        --env LABELS="org.opencontainers.image.title=${image_name}$'\n'org.opencontainers.image.version=localbuild-$(date +%Y%m%d-%H:%M:%S)$'\n''io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/README.md'$'\n''io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4'$'\n'" \
        --env "DESCRIPTION='An interpretation of the Ubuntu spirit built on Fedora technology'" \
        --env VERSION_FN=/workspace/version.txt \
        --env OUT_REF="oci:$OUT_NAME" \
        --env GIT_DIR="/var/git" \
        --user 0:0 \
        ghcr.io/hhd-dev/rechunk:latest \
        /sources/rechunk/3_chunk.sh

    # Cleanup
    just sudoif "find ${OUT_NAME} -type d -exec chmod 0755 {} \;" || true
    just sudoif "find ${OUT_NAME}* -type f -exec chmod 0644 {} \;" || true
    if [[ "${UID}" -gt 0 ]]; then
        just sudoif chown ${UID}:${GROUPS} -R "${PWD}"
    fi
    just sudoif podman volume rm cache_ostree
    just sudoif podman rmi localhost/"${image_name}":"${tag}"

    # Load Image into Podman Store
    IMAGE=$(podman pull oci:"${PWD}"/"${OUT_NAME}")
    podman tag ${IMAGE} localhost/"${image_name}":"${tag}"

# Run Container
run image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail
    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    if [[ "${flavor}" =~ main ]]; then
        image_name="${image}"
    else
        image_name="${image}-${flavor}"
    fi

    # Check if image exists
    ID=$(podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        just build "$image" "$tag" "$flavor"
    fi

    # Run Container
    podman run -it --rm localhost/"${image_name}":"${tag}" bash

# Build ISO
build-iso image="bluefin" tag="latest" flavor="main" ghcr="0":
    #!/usr/bin/bash
    set -eoux pipefail
    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    if [[ "${flavor}" =~ main ]]; then
        image_name="${image}"
    else
        image_name="${image}-${flavor}"
    fi

    build_dir="${image_name}_build"
    mkdir -p "$build_dir"

    if [[ -f "${build_dir}/${image_name}.iso" || -f "${build_dir}/${image_name}.iso-CHECKSUM" ]]; then
        echo "ERROR - ISO or Checksum already exist. Please mv or rm to build new ISO"
        exit 1
    fi

    # Local or Github Build
    if [[ "{{ ghcr }}" == "1" ]]; then
        IMAGE_FULL=ghcr.io/ublue-os/"${image_name}":"${tag}"
        IMAGE_REPO=ghcr.io/ublue-os
        podman pull "${IMAGE_FULL}"
    else
        IMAGE_FULL=localhost/"${image_name}":"${tag}"
        IMAGE_REPO=localhost
        ID=$(podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ -z "$ID" ]]; then
            just build "$image" "$tag" "$flavor"
        fi
    fi

    # Load Image into rootful podman
    if [[ "${UID}" -gt 0 ]]; then
        just sudoif podman image scp "${UID}"@localhost::"${IMAGE_FULL}" root@localhost::"${IMAGE_FULL}"
    fi

    # Flatpak list for bluefin/aurora
    if [[ "${image_name}" =~ bluefin ]]; then
        FLATPAK_DIR_SHORTNAME="bluefin_flatpaks"
    elif [[ "${image_name}" =~ aurora ]]; then
        FLATPAK_DIR_SHORTNAME="aurora_flatpaks"
    fi

    # Generate Flatpak List
    TEMP_FLATPAK_INSTALL_DIR="$(mktemp -d -p /tmp flatpak-XXXXX)"
    flatpak_refs=()
    while IFS= read -r line; do
        flatpak_refs+=("$line")
    done < "${FLATPAK_DIR_SHORTNAME}/flatpaks"

    # Add DX Flatpaks if needed
    if [[ "${image_name}" =~ dx ]]; then
        while IFS= read -r line; do
            flatpak_refs+=("$line")
        done < "dx_flatpaks/flatpaks"
    fi

    echo "Flatpak refs: ${flatpak_refs[@]}"

    # Generate Install Script for Flatpaks
    tee "${TEMP_FLATPAK_INSTALL_DIR}/install-flatpaks.sh"<<EOF
    mkdir -p /flatpak/flatpak /flatpak/triggers
    mkdir -p /var/tmp
    chmod -R 1777 /var/tmp
    flatpak config --system --set languages "*"
    flatpak remote-add --system flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install --system -y flathub ${flatpak_refs[@]}
    ostree refs --repo=\${FLATPAK_SYSTEM_DIR}/repo | grep '^deploy/' | grep -v 'org\.freedesktop\.Platform\.openh264' | sed 's/^deploy\///g' > /output/flatpaks-with-deps
    EOF

    # Create Flatpak List with dependencies
    flatpak_list_args=()
    flatpak_list_args+=("--rm" "--privileged")
    flatpak_list_args+=("--entrypoint" "/usr/bin/bash")
    flatpak_list_args+=("--env" "FLATPAK_SYSTEM_DIR=/flatpak/flatpak")
    flatpak_list_args+=("--env" "FLATPAK_TRIGGERSDIR=/flatpak/triggers")
    flatpak_list_args+=("--volume" "$(realpath ./${build_dir}):/output")
    flatpak_list_args+=("--volume" "${TEMP_FLATPAK_INSTALL_DIR}:/temp_flatpak_install_dir")
    flatpak_list_args+=("${IMAGE_FULL}" /temp_flatpak_install_dir/install-flatpaks.sh)

    if [[ ! -f "${build_dir}/flatpaks-with-deps" ]]; then
        podman run "${flatpak_list_args[@]}"
    else
        echo "WARNING - Reusing previous determined flatpaks-with-deps"
    fi

    # List Flatpaks with Dependencies
    cat "${build_dir}/flatpaks-with-deps"

    # Build ISO
    iso_build_args=()
    iso_build_args+=("--rm" "--privileged" "--pull=newer")
    iso_build_args+=(--volume "/var/lib/containers/storage:/var/lib/containers/storage")
    iso_build_args+=(--volume "${PWD}:/github/workspace/")
    iso_build_args+=(ghcr.io/jasonn3/build-container-installer:latest)
    iso_build_args+=(ARCH="x86_64")
    iso_build_args+=(ENROLLMENT_PASSWORD="universalblue")
    iso_build_args+=(FLATPAK_REMOTE_REFS_DIR="/github/workspace/${build_dir}")
    iso_build_args+=(IMAGE_NAME="${image_name}")
    iso_build_args+=(IMAGE_REPO="${IMAGE_REPO}")
    iso_build_args+=(IMAGE_SIGNED="true")
    iso_build_args+=(IMAGE_SRC="containers-storage:${IMAGE_FULL}")
    iso_build_args+=(IMAGE_TAG="${tag}")
    iso_build_args+=(ISO_NAME="/github/workspace/${build_dir}/${image_name}.iso")
    iso_build_args+=(SECURE_BOOT_KEY_URL="https://github.com/ublue-os/akmods/raw/main/certs/public_key.der")
    if [[ "${image_name}" =~ bluefin ]]; then
        iso_build_args+=(VARIANT="Silverblue")
    else
        iso_build_args+=(VARIANT="Kinoite")
    fi
    iso_build_args+=(VERSION="$(skopeo inspect containers-storage:${IMAGE_FULL} | jq -r '.Labels["ostree.linux"]' | grep -oP 'fc\K[0-9]+')")
    iso_build_args+=(WEBUI="false")

    just sudoif podman run "${iso_build_args[@]}"
    just sudoif chown "${UID}:${GROUPS}" -R "${PWD}"

# Build ISO using GHCR Image
build-iso-ghcr image="bluefin" tag="latest" flavor="main":
    @just build-iso {{ image }} {{ tag }} {{ flavor }} ghcr

# Run ISO
run-iso image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail
    image={{ image }}
    tag={{ tag }}
    flavor={{ flavor }}

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    if [[ "${flavor}" =~ main ]]; then
        image_name="${image}"
    else
        image_name="${image}-${flavor}"
    fi

    # Check if ISO Exists
    if [[ ! -f "${image_name}_build/${image_name}.iso" ]]; then
        just build-iso "$image" "$tag" "$flavor"
    fi

    # Determine which port to use
    port=8006;
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_name}_build/${image_name}.iso":"/boot.iso")
    run_args+=(docker.io/qemux/qemu-docker)
    podman run "${run_args[@]}" &
    xdg-open http://localhost:${port}
    fg "%podman"

# Test Changelogs
changelogs branch="stable":
    #!/usr/bin/bash
    set -eoux pipefail
    python3 ./.github/changelogs.py {{ branch }} ./output.env ./changelog.md --workdir .
