repo_organization := "ublue-os"
rechunker_image := "ghcr.io/hhd-dev/rechunk:v1.0.1"
iso_builder_image := "ghcr.io/jasonn3/build-container-installer:v1.2.3"
images := '(
    [bluefin]=bluefin
    [bluefin-dx]=bluefin-dx
)'
flavors := '(
    [main]=main
    [nvidia]=nvidia
    [nvidia-open]=nvidia-open
    [hwe]=hwe
    [hwe-nvidia]=hwe-nvidia
    [hwe-nvidia-open]=hwe-nvidia-open
    [asus]=asus
    [asus-nvidia]=asus-nvidia
    [asus-nvidia-open]=asus-nvidia-open
    [surface]=surface
    [surface-nvidia]=surface-nvidia
    [surface-nvidia-open]=surface-nvidia-open
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
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# Check if valid combo
[group('Utility')]
[private]
validate $image $tag $flavor:
    #!/usr/bin/bash
    set -eou pipefail
    declare -A images={{ images }}
    declare -A tags={{ tags }}
    declare -A flavors={{ flavors }}

    # Handle Stable Daily
    if [[ "${tag}" == "stable-daily" ]]; then
        tag="stable"
    fi

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
    if [[ -z "$checkflavor" ]]; then
        echo "Invalid flavor..."
        exit 1
    fi
    if [[ ! "$checktag" =~ latest && "$checkflavor" =~ hwe|asus|surface ]]; then
        echo "HWE images are only built on latest..."
        exit 1
    fi

# sudoif bash function
[group('Utility')]
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
[group('Image')]
build $image="bluefin" $tag="latest" $flavor="main" rechunk="0" ghcr="0" pipeline="0" $kernel_pin="":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    # Base Image
    base_image_name="silverblue"

    # Target
    if [[ "${image}" =~ dx ]]; then
        target="dx"
    else
        target="base"
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

    # Fedora Version
    if [[ {{ ghcr }} == "0" ]]; then
        rm -f /tmp/manifest.json
    fi
    fedora_version=$(just fedora_version '{{ image }}' '{{ tag }}' '{{ flavor }}' '{{ kernel_pin }}')

    # Verify Base Image with cosign
    just verify-container "${base_image_name}-main:${fedora_version}"

    # Kernel Release/Pin
    if [[ -z "${kernel_pin:-}" ]]; then
        kernel_release=$(skopeo inspect --retry-times 3 docker://ghcr.io/ublue-os/${akmods_flavor}-kernel:"${fedora_version}" | jq -r '.Labels["ostree.linux"]')
    else
        kernel_release="${kernel_pin}"
    fi

    # Verify Containers with Cosign
    just verify-container "${akmods_flavor}-kernel:${kernel_release}"
    just verify-container "akmods:${akmods_flavor}-${fedora_version}-${kernel_release}"
    if [[ "${akmods_flavor}" =~ coreos ]]; then
        just verify-container "akmods-zfs:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi
    if [[ "${flavor}" =~ nvidia-open ]]; then
        just verify-container "akmods-nvidia-open:${akmods_flavor}-${fedora_version}-${kernel_release}"
    elif [[ "${flavor}" =~ nvidia ]]; then
        just verify-container "akmods-nvidia:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi

    # Get Version
    if [[ "${tag}" =~ stable ]]; then
        ver="${fedora_version}.$(date +%Y%m%d)"
    else
        ver="${tag}-${fedora_version}.$(date +%Y%m%d)"
    fi

    # Build Arguments
    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "AKMODS_FLAVOR=${akmods_flavor}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE_NAME=${base_image_name}")
    BUILD_ARGS+=("--build-arg" "FEDORA_MAJOR_VERSION=${fedora_version}")
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR={{ repo_organization }}")
    BUILD_ARGS+=("--build-arg" "KERNEL=${kernel_release}")
    if [[ -z "$(git status -s)" ]]; then
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
    if [[ "{{ rechunk }}" == "1" && "{{ ghcr }}" == "1" && "{{ pipeline }}" == "1" ]]; then
        just rechunk "${image}" "${tag}" "${flavor}" 1 1
    elif [[ "{{ rechunk }}" == "1" && "{{ ghcr }}" == "1" ]]; then
        just rechunk "${image}" "${tag}" "${flavor}" 1
    elif [[ "{{ rechunk }}" == "1" ]]; then
        just rechunk "${image}" "${tag}" "${flavor}"
    fi

# Build Image and Rechunk
[group('Image')]
build-rechunk image="bluefin" tag="latest" flavor="main" kernel_pin="":
    @just build {{ image }} {{ tag }} {{ flavor }} 1 0 0 {{ kernel_pin }}

# Build Image with GHCR Flag
[group('Image')]
build-ghcr image="bluefin" tag="latest" flavor="main" kernel_pin="":
    #!/usr/bin/bash
    if [[ "${UID}" -gt "0" ]]; then
        echo "Must Run with sudo or as root..."
        exit 1
    fi
    just build {{ image }} {{ tag }} {{ flavor }} 0 1 0 {{ kernel_pin }}

# Build Image for Pipeline:
[group('Image')]
build-pipeline image="bluefin" tag="latest" flavor="main" kernel_pin="":
    #!/usr/bin/bash
    if [[ "${UID}" -gt "0" ]]; then
        echo "Must Run with sudo or as root..."
        exit 1
    fi
    just build {{ image }} {{ tag }} {{ flavor }} 1 1 1 {{ kernel_pin }}

# Rechunk Image
[group('Image')]
[private]
rechunk $image="bluefin" $tag="latest" $flavor="main" ghcr="0" pipeline="0":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    # Check if image is already built
    ID=$(podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        just build "${image}" "${tag}" "${flavor}"
    fi

    # Load into Rootful Podman
    ID=$(just sudoif podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::localhost/"${image_name}":"${tag}" root@localhost::localhost/"${image_name}":"${tag}"
        rm -rf "${COPYTMP}"
    fi

    # Prep Container
    CREF=$(just sudoif podman create localhost/"${image_name}":"${tag}" bash)
    OLD_IMAGE=$(just sudoif podman inspect $CREF | jq -r '.[].Image')
    OUT_NAME="${image_name}_build"
    MOUNT=$(just sudoif podman mount "${CREF}")

    # Fedora Version
    fedora_version=$(just sudoif podman inspect $CREF | jq -r '.[].Config.Labels["ostree.linux"]' | grep -oP 'fc\K[0-9]+')

    # Label Version
    if [[ "{{ tag }}" =~ stable ]]; then
        VERSION="${fedora_version}.$(date +%Y%m%d)"
    else
        VERSION="${tag}-${fedora_version}.$(date +%Y%m%d)"
    fi

    # Cleanup Space during Github Action
    if [[ "{{ ghcr }}" == "1" ]]; then
        base_image_name=silverblue-main
        if [[ "${tag}" =~ stable ]]; then
            tag="stable-daily"
        fi
        ID=$(just sudoif podman images --filter reference=ghcr.io/ublue-os/"${base_image_name}":${fedora_version} --format "'{{ '{{.ID}}' }}'")
        if [[ -n "$ID" ]]; then
            podman rmi "$ID"
        fi
    fi

    # Rechunk Container
    rechunker="{{ rechunker_image }}"

    # Run Rechunker's Prune
    just sudoif podman run --rm \
        --pull=newer \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        "${rechunker}" \
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
        "${rechunker}" \
        /sources/rechunk/2_create.sh

    # Cleanup Temp Container Reference
    just sudoif podman unmount "$CREF"
    just sudoif podman rm "$CREF"
    just sudoif podman rmi "$OLD_IMAGE"

    SHA="dedbeef"
    if [[ -z "$(git status -s)" ]]; then
        SHA=$(git rev-parse HEAD)
    fi
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
        --env LABELS="org.opencontainers.image.title=${image_name}$'\n''io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/README.md'$'\n''io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4'$'\n'" \
        --env "DESCRIPTION='An interpretation of the Ubuntu spirit built on Fedora technology'" \
        --env "VERSION=${VERSION}" \
        --env VERSION_FN=/workspace/version.txt \
        --env OUT_REF="oci:$OUT_NAME" \
        --env GIT_DIR="/var/git" \
        --env REVISION="$SHA" \
        --user 0:0 \
        "${rechunker}" \
        /sources/rechunk/3_chunk.sh

    # Fix Permissions of OCI
    if [[ "${UID}" -gt "0" ]]; then
        just sudoif chown "${UID}:${GROUPS}" -R "${PWD}"
    elif [[ -n "${SUDO_UID:-}" ]]; then
        chown "${SUDO_UID}":"${SUDO_GID}" -R "${PWD}"
    fi

    # Remove cache_ostree
    just sudoif podman volume rm cache_ostree

    # Show OCI Labels
    just sudoif skopeo inspect oci:"${PWD}"/"${OUT_NAME}" | jq -r '.Labels'

    # Pipeline Checks
    if [[ {{ pipeline }} == "1" && -n "${SUDO_USER:-}" ]]; then
        sudo -u "${SUDO_USER}" just load-rechunk "${image}" "${tag}" "${flavor}"
        sudo -u "${SUDO_USER}" just secureboot "${image}" "${tag}" "${flavor}"
    fi

# Load OCI into Podman Store
[group('Image')]
load-rechunk image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eou pipefail

    # Validate
    just validate {{ image }} {{ tag }} {{ flavor }}

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    # Load Image
    OUT_NAME="${image_name}_build"
    IMAGE=$(podman pull oci:"${PWD}"/"${OUT_NAME}")
    podman tag ${IMAGE} localhost/"${image_name}":{{ tag }}

    # Cleanup
    just sudoif "rm -rf ${OUT_NAME}*"
    just sudoif "rm -f previous.manifest.json"

# Run Container
[group('Image')]
run $image="bluefin" $tag="latest" $flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    # Check if image exists
    ID=$(podman images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        just build "$image" "$tag" "$flavor"
    fi

    # Run Container
    podman run -it --rm localhost/"${image_name}":"${tag}" bash

# Build ISO
[group('ISO')]
build-iso $image="bluefin" $tag="latest" $flavor="main" ghcr="0" pipeline="0":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    build_dir="${image_name}_build"
    mkdir -p "$build_dir"

    if [[ -f "${build_dir}/${image_name}-${tag}.iso" || -f "${build_dir}/${image_name}-${tag}.iso-CHECKSUM" ]]; then
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

    # Fedora Version
    FEDORA_VERSION=$(podman inspect ${IMAGE_FULL} | jq -r '.[]["Config"]["Labels"]["ostree.linux"]' | grep -oP 'fc\K[0-9]+')

    # Load Image into rootful podman
    if [[ "${UID}" -gt 0 && {{ ghcr }} == "0" ]]; then
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        just sudoif TMPDIR=${COPYTMP} podman image scp "${UID}"@localhost::"${IMAGE_FULL}" root@localhost::"${IMAGE_FULL}"
        rm -rf "${COPYTMP}"
    fi

    FLATPAK_DIR_SHORTNAME="bluefin_flatpaks"

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

    if [[ "{{ pipeline }}" == "1" ]]; then
    	podman rmi ${IMAGE_FULL}
    fi

    # List Flatpaks with Dependencies
    cat "${build_dir}/flatpaks-with-deps"

    # Build ISO
    iso_build_args=()
    iso_build_args+=("--rm" "--privileged" "--pull=newer")
    if [[ "{{ ghcr }}" == "0" ]]; then
    	iso_build_args+=(--volume "/var/lib/containers/storage:/var/lib/containers/storage")
    fi
    iso_build_args+=(--volume "${PWD}:/github/workspace/")
    iso_build_args+=("{{ iso_builder_image }}")
    iso_build_args+=(ARCH="x86_64")
    iso_build_args+=(ENROLLMENT_PASSWORD="universalblue")
    iso_build_args+=(FLATPAK_REMOTE_REFS_DIR="/github/workspace/${build_dir}")
    iso_build_args+=(IMAGE_NAME="${image_name}")
    iso_build_args+=(IMAGE_REPO="${IMAGE_REPO}")
    iso_build_args+=(IMAGE_SIGNED="true")
    if [[ "{{ ghcr }}" == "0" ]]; then
    	iso_build_args+=(IMAGE_SRC="containers-storage:${IMAGE_FULL}")
    fi
    iso_build_args+=(IMAGE_TAG="${tag}")
    iso_build_args+=(ISO_NAME="/github/workspace/${build_dir}/${image_name}-${tag}.iso")
    iso_build_args+=(SECURE_BOOT_KEY_URL="https://github.com/ublue-os/akmods/raw/main/certs/public_key.der")
    iso_build_args+=(VARIANT="Silverblue")
    iso_build_args+=(VERSION="${FEDORA_VERSION}")
    iso_build_args+=(WEB_UI="false")

    just sudoif podman run "${iso_build_args[@]}"

    if [[ "${UID}" -gt "0" ]]; then
        just sudoif chown "${UID}:${GROUPS}" -R "${PWD}"
    elif [[ -n "${SUDO_UID:-}" ]]; then
        chown "${SUDO_UID}":"${SUDO_GID}" -R "${PWD}"
    fi

# Build ISO using GHCR Image
[group('ISO')]
build-iso-ghcr image="bluefin" tag="latest" flavor="main":
    @just build-iso {{ image }} {{ tag }} {{ flavor }} 1

# Run ISO
[group('ISO')]
run-iso $image="bluefin" $tag="latest" $flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name {{ image }} {{ tag }} {{ flavor }})

    # Check if ISO Exists
    if [[ ! -f "${image_name}_build/${image_name}-${tag}.iso" ]]; then
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
    run_args+=(--volume "${PWD}/${image_name}_build/${image_name}-${tag}.iso":"/boot.iso")
    run_args+=(docker.io/qemux/qemu-docker)
    podman run "${run_args[@]}" &
    xdg-open http://localhost:${port}
    fg "%podman"

# Test Changelogs
[group('Changelogs')]
changelogs branch="stable" handwritten="":
    #!/usr/bin/bash
    set -eou pipefail
    python3 ./.github/changelogs.py "{{ branch }}" ./output.env ./changelog.md --workdir . --handwritten "{{ handwritten }}"

# Verify Container with Cosign
[group('Utility')]
verify-container container="" registry="ghcr.io/ublue-os" key="":
    #!/usr/bin/bash
    set -eoux pipefail

    # Get Cosign if Needed
    if [[ ! $(command -v cosign) ]]; then
        COSIGN_CONTAINER_ID=$(just sudoif podman create cgr.dev/chainguard/cosign:latest bash)
        just sudoif podman cp "${COSIGN_CONTAINER_ID}":/usr/bin/cosign /usr/local/bin/cosign
        just sudoif podman rm -f "${COSIGN_CONTAINER_ID}"
    fi

    # Verify Cosign Image Signatures if needed
    if [[ -n "${COSIGN_CONTAINER_ID:-}" ]]; then
        if ! cosign verify --certificate-oidc-issuer=https://token.actions.githubusercontent.com --certificate-identity=https://github.com/chainguard-images/images/.github/workflows/release.yaml@refs/heads/main cgr.dev/chainguard/cosign >/dev/null; then
            echo "NOTICE: Failed to verify cosign image signatures."
            exit 1
        fi
    fi

    # Public Key for Container Verification
    key={{ key }}
    if [[ -z "${key:-}" ]]; then
        key="https://raw.githubusercontent.com/ublue-os/main/main/cosign.pub"
    fi

    # Verify Container using cosign public key
    if ! cosign verify --key "${key}" "{{ registry }}"/"{{ container }}" >/dev/null; then
        echo "NOTICE: Verification failed. Please ensure your public key is correct."
        exit 1
    fi

# Secureboot Check
[group('Utility')]
secureboot $image="bluefin" $tag="latest" $flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    just validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$(just image_name ${image} ${tag} ${flavor})

    # Get the vmlinuz to check
    kernel_release=$(podman inspect "${image_name}":"${tag}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$(podman create "${image_name}":"${tag}" bash)
    podman cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz /tmp/vmlinuz
    podman rm "$TMP"

    # Get the Public Certificates
    curl --retry 3 -Lo /tmp/kernel-sign.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key.der
    curl --retry 3 -Lo /tmp/akmods.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key_2.der
    openssl x509 -in /tmp/kernel-sign.der -out /tmp/kernel-sign.crt
    openssl x509 -in /tmp/akmods.der -out /tmp/akmods.crt

    # Make sure we have sbverify
    CMD="$(command -v sbverify)"
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        podman run -dt \
            --entrypoint /bin/sh \
            --volume /tmp/vmlinuz:/tmp/vmlinuz:z \
            --volume /tmp/kernel-sign.crt:/tmp/kernel-sign.crt:z \
            --volume /tmp/akmods.crt:/tmp/akmods.crt:z \
            --name ${temp_name} \
            alpine:edge
        podman exec ${temp_name} apk add sbsigntool
        CMD="podman exec ${temp_name} /usr/bin/sbverify"
    fi

    # Confirm that Signatures Are Good
    $CMD --list /tmp/vmlinuz
    returncode=0
    if ! $CMD --cert /tmp/kernel-sign.crt /tmp/vmlinuz || ! $CMD --cert /tmp/akmods.crt /tmp/vmlinuz; then
        echo "Secureboot Signature Failed...."
        returncode=1
    fi
    if [[ -n "${temp_name:-}" ]]; then
        podman rm -f "${temp_name}"
    fi
    exit "$returncode"

# Get Fedora Version of an image
[group('Utility')]
[private]
fedora_version image="bluefin" tag="latest" flavor="main" $kernel_pin="":
    #!/usr/bin/bash
    set -eou pipefail
    just validate {{ image }} {{ tag }} {{ flavor }}
    if [[ ! -f /tmp/manifest.json ]]; then
        if [[ "{{ tag }}" =~ stable ]]; then
            # CoreOS does not uses cosign
            skopeo inspect --retry-times 3 docker://quay.io/fedora/fedora-coreos:stable > /tmp/manifest.json
        else
            skopeo inspect --retry-times 3 docker://ghcr.io/ublue-os/base-main:"{{ tag }}" > /tmp/manifest.json
        fi
    fi
    fedora_version=$(jq -r '.Labels["ostree.linux"]' < /tmp/manifest.json | grep -oP 'fc\K[0-9]+')
    if [[ -n "${kernel_pin:-}" ]]; then
        fedora_version=$(echo "${kernel_pin}" | grep -oP 'fc\K[0-9]+')
    fi
    echo "${fedora_version}"

# Image Name
[group('Utility')]
[private]
image_name image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eou pipefail
    just validate {{ image }} {{ tag }} {{ flavor }}
    if [[ "{{ flavor }}" =~ main ]]; then
        image_name={{ image }}
    else
        image_name="{{ image }}-{{ flavor }}"
    fi
    echo "${image_name}"

# Generate Tags
[group('Utility')]
generate-build-tags image="bluefin" tag="latest" flavor="main" kernel_pin="" ghcr="0" $version="" github_event="" github_number="":
    #!/usr/bin/bash
    set -eou pipefail

    TODAY="$(date +%A)"
    WEEKLY="Sunday"
    if [[ {{ ghcr }} == "0" ]]; then
        rm -f /tmp/manifest.json
    fi
    FEDORA_VERSION="$(just fedora_version '{{ image }}' '{{ tag }}' '{{ flavor }}' '{{ kernel_pin }}')"
    DEFAULT_TAG=$(just generate-default-tag {{ tag }} {{ ghcr }})
    IMAGE_NAME=$(just image_name {{ image }} {{ tag }} {{ flavor }})
    # Use Build Version from Rechunk
    if [[ -z "${version:-}" ]]; then
        version="{{ tag }}-${FEDORA_VERSION}.$(date +%Y%m%d)"
    fi
    version=${version#{{ tag }}-}

    # Arrays for Tags
    BUILD_TAGS=()
    COMMIT_TAGS=()

    # Commit Tags
    github_number="{{ github_number }}"
    SHA_SHORT="$(git rev-parse --short HEAD)"
    if [[ "{{ ghcr }}" == "1" ]]; then
        COMMIT_TAGS+=(pr-${github_number:-}-{{ tag }}-${version})
        COMMIT_TAGS+=(${SHA_SHORT}-{{ tag }}-${version})
    fi

    # Convenience Tags
    if [[ "{{ tag }}" =~ stable ]]; then
        BUILD_TAGS+=("stable-daily" "${version}" "stable-daily-${version}" "stable-daily-${version:3}")
    else
        BUILD_TAGS+=("{{ tag }}" "{{ tag }}-${version}" "{{ tag }}-${version:3}")
    fi

    # Weekly Stable / Rebuild Stable on workflow_dispatch
    github_event="{{ github_event }}"
    if [[ "{{ tag }}" =~ "stable" && "${WEEKLY}" == "${TODAY}" && "${github_event}" =~ schedule ]]; then
        BUILD_TAGS+=("stable" "stable-${version}" "stable-${version:3}")
    elif [[ "{{ tag }}" =~ "stable" && "${github_event}" =~ workflow_dispatch|workflow_call ]]; then
        BUILD_TAGS+=("stable" "stable-${version}" "stable-${version:3}")
    elif [[ "{{ tag }}" =~ "stable" && "{{ ghcr }}" == "0" ]]; then
        BUILD_TAGS+=("stable" "stable-${version}" "stable-${version:3}")
    elif [[ ! "{{ tag }}" =~ stable|beta ]]; then
        BUILD_TAGS+=("${FEDORA_VERSION}" "${FEDORA_VERSION}-${version}" "${FEDORA_VERSION}-${version:3}")
    fi

    if [[ "${github_event}" == "pull_request" ]]; then
        alias_tags=("${COMMIT_TAGS[@]}")
    else
        alias_tags=("${BUILD_TAGS[@]}")
    fi

    echo "${alias_tags[*]}"

# Generate Default Tag
[group('Utility')]
generate-default-tag tag="latest" ghcr="0":
    #!/usr/bin/bash
    set -eou pipefail

    # Default Tag
    if [[ "{{ tag }}" =~ stable && "{{ ghcr }}" == "1" ]]; then
        DEFAULT_TAG="stable-daily"
    elif [[ "{{ tag }}" =~ stable && "{{ ghcr }}" == "0" ]]; then
        DEFAULT_TAG="stable"
    else
        DEFAULT_TAG="{{ tag }}"
    fi

    echo "${DEFAULT_TAG}"

# Tag Images
[group('Utility')]
tag-images image_name="" default_tag="" tags="":
    #!/usr/bin/bash
    set -eou pipefail

    # Get Image, and untag
    IMAGE=$(podman inspect localhost/{{ image_name }}:{{ default_tag }} | jq -r .[].Id)
    podman untag localhost/{{ image_name }}:{{ default_tag }}

    # Tag Image
    for tag in {{ tags }}; do
        podman tag $IMAGE {{ image_name }}:${tag}
    done

    # HWE Tagging
    if [[ "{{ image_name }}" =~ hwe ]]; then

        image_name="{{ image_name }}"
        asus_name="${image_name/hwe/asus}"
        surface_name="${image_name/hwe/surface}"

        for tag in {{ tags }}; do
            podman tag "${IMAGE}" "${asus_name}":${tag}
            podman tag "${IMAGE}" "${surface_name}":${tag}
        done
    fi

    # Show Images
    podman images
