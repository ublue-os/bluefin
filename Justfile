repo_organization := "ublue-os"
rechunker_image := "ghcr.io/ublue-os/legacy-rechunk:v1.0.1-x86_64@sha256:2627cbf92ca60ab7372070dcf93b40f457926f301509ffba47a04d6a9e1ddaf7"
common_image := "ghcr.io/projectbluefin/common:latest"
brew_image := "ghcr.io/ublue-os/brew:latest"
images := '(
    [bluefin]=bluefin
    [bluefin-dx]=bluefin-dx
)'
flavors := '(
    [main]=main
    [nvidia-open]=nvidia-open
)'
tags := '(
    [gts]=gts
    [stable]=stable
    [latest]=latest
    [beta]=beta
)'
export SUDO_DISPLAY := if `if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then echo true; fi` == "true" { "true" } else { "false" }
export SUDOIF := if `id -u` == "0" { "" } else if SUDO_DISPLAY == "true" { "sudo --askpass" } else { "sudo" }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") }
export PULL_POLICY := if PODMAN =~ "docker" { "missing" } else { "newer" }
just := just_executable()

[private]
default:
    @{{ just }} --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	{{ just }} --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	{{ just }} --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --unstable --fmt -f Justfile || { exit 1; }

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

# Build Image
[group('Image')]
build $image="bluefin" $tag="latest" $flavor="main" rechunk="0" ghcr="0" pipeline="0" $kernel_pin="":
    #!/usr/bin/bash

    echo "::group:: Build Prep"
    set -eoux pipefail

    # Validate
    {{ just }} validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$({{ just }} image_name {{ image }} {{ tag }} {{ flavor }})

    common_image_sha=$(yq -r '.images[] | select(.name == "common") | .digest' image-versions.yml)
    brew_image_sha=$(yq -r '.images[] | select(.name == "brew") | .digest' image-versions.yml)

    # Base Image
    base_image_name="silverblue"


    # AKMODS Flavor and Kernel Version
    if [[ "${flavor}" =~ hwe ]]; then
        akmods_flavor="bazzite"
    elif [[ "${tag}" =~ gts|stable ]]; then
        akmods_flavor="coreos-stable"
    elif [[ "${tag}" =~ beta ]]; then
        akmods_flavor="main"
    else
        akmods_flavor="main"
    fi

    # Fedora Version
    if [[ {{ ghcr }} == "0" ]]; then
        rm -f /tmp/manifest.json
    fi
    fedora_version=$({{ just }} fedora_version '{{ image }}' '{{ tag }}' '{{ flavor }}' '{{ kernel_pin }}')

    # Verify Base Image with cosign
    {{ just }} verify-container "${base_image_name}-main:${fedora_version}"

    # Kernel Release/Pin
    if [[ -z "${kernel_pin:-}" ]]; then
        kernel_release=$(skopeo inspect --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${akmods_flavor}"-"${fedora_version}" | jq -r '.Labels["ostree.linux"]')
    else
        kernel_release="${kernel_pin}"
    fi

    # Verify Containers with Cosign
    {{ just }} verify-container "akmods:${akmods_flavor}-${fedora_version}-${kernel_release}"
    if [[ "${akmods_flavor}" =~ coreos ]]; then
        {{ just }} verify-container "akmods-zfs:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi
    if [[ "${flavor}" =~ nvidia-open ]]; then
        {{ just }} verify-container "akmods-nvidia-open:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi

    {{ just }} verify-container "common:latest@${common_image_sha}" ghcr.io/projectbluefin https://raw.githubusercontent.com/projectbluefin/common/refs/heads/main/cosign.pub
    {{ just }} verify-container "brew:latest@${brew_image_sha}" ghcr.io/ublue-os https://raw.githubusercontent.com/ublue-os/brew/refs/heads/main/cosign.pub

    # Get Version
    if [[ "${tag}" =~ stable ]]; then
        ver="${fedora_version}.$(date +%Y%m%d)"
    else
        ver="${tag}-${fedora_version}.$(date +%Y%m%d)"
    fi
    skopeo list-tags docker://ghcr.io/{{ repo_organization }}/${image_name} > /tmp/repotags.json
    if [[ $(jq "any(.Tags[]; contains(\"$ver\"))" < /tmp/repotags.json) == "true" ]]; then
        POINT="1"
        while $(jq -e "any(.Tags[]; contains(\"$ver.$POINT\"))" < /tmp/repotags.json)
        do
            (( POINT++ ))
        done
    fi
    if [[ -n "${POINT:-}" ]]; then
        ver="${ver}.$POINT"
    fi

    # Build Arguments
    BUILD_ARGS=()
    # Target
    if [[ "${image}" =~ dx ]]; then
        BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=dx")
        target="dx"
    fi
    BUILD_ARGS+=("--build-arg" "AKMODS_FLAVOR=${akmods_flavor}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE_NAME=${base_image_name}")
    BUILD_ARGS+=("--build-arg" "COMMON_IMAGE={{ common_image }}")
    BUILD_ARGS+=("--build-arg" "COMMON_IMAGE_SHA=${common_image_sha}")
    BUILD_ARGS+=("--build-arg" "BREW_IMAGE={{ brew_image }}")
    BUILD_ARGS+=("--build-arg" "BREW_IMAGE_SHA=${brew_image_sha}")
    BUILD_ARGS+=("--build-arg" "FEDORA_MAJOR_VERSION=${fedora_version}")
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR={{ repo_organization }}")
    BUILD_ARGS+=("--build-arg" "KERNEL=${kernel_release}")
    BUILD_ARGS+=("--build-arg" "VERSION=${ver}")
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi
    BUILD_ARGS+=("--build-arg" "UBLUE_IMAGE_TAG=${tag}")
    if [[ "${PODMAN}" =~ docker && "${TERM}" == "dumb" ]]; then
        BUILD_ARGS+=("--progress" "plain")
    fi

    # Labels
    LABELS=()
    LABELS+=("--label" "org.opencontainers.image.title=${image_name}")
    LABELS+=("--label" "org.opencontainers.image.version=${ver}")
    LABELS+=("--label" "ostree.linux=${kernel_release}")
    LABELS+=("--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/README.md")
    LABELS+=("--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4")
    LABELS+=("--label" "org.opencontainers.image.description=The next generation Linux workstation, designed for reliability, performance, and sustainability.")
    LABELS+=("--label" "containers.bootc=1")
    LABELS+=("--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)")
    LABELS+=("--label" "org.opencontainers.image.source=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/Containerfile")
    LABELS+=("--label" "org.opencontainers.image.url=https://projectbluefin.io")
    LABELS+=("--label" "org.opencontainers.image.vendor={{ repo_organization }}")
    LABELS+=("--label" "io.artifacthub.package.deprecated=false")
    LABELS+=("--label" "io.artifacthub.package.keywords=bootc,bluefin,ublue,universal-blue")
    LABELS+=("--label" "io.artifacthub.package.maintainers=[{\"name\": \"castrojo\", \"email\": \"jorge.castro@gmail.com\"}]")

    echo "::endgroup::"
    echo "::group:: Build Container"

    # Build Image
    PODMAN_BUILD_ARGS=("${BUILD_ARGS[@]}" "${LABELS[@]}" --tag localhost/"${image_name}:${tag}" --file Containerfile)

    # Add GitHub token secret if available (for CI/CD)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "Adding GitHub token as build secret"
        PODMAN_BUILD_ARGS+=(--secret "id=GITHUB_TOKEN,env=GITHUB_TOKEN")
    else
        echo "No GitHub token found - build may hit rate limit"
    fi

    ${PODMAN} build "${PODMAN_BUILD_ARGS[@]}" .
    echo "::endgroup::"

    # Rechunk
    if [[ "{{ rechunk }}" == "1" && "{{ ghcr }}" == "1" && "{{ pipeline }}" == "1" ]]; then
        ${SUDOIF} {{ just }} rechunk "${image}" "${tag}" "${flavor}" 1 1
    elif [[ "{{ rechunk }}" == "1" && "{{ ghcr }}" == "1" ]]; then
        ${SUDOIF} {{ just }} rechunk "${image}" "${tag}" "${flavor}" 1
    elif [[ "{{ rechunk }}" == "1" ]]; then
        ${SUDOIF} {{ just }} rechunk "${image}" "${tag}" "${flavor}"
    fi

# Build Image and Rechunk
[group('Image')]
build-rechunk image="bluefin" tag="latest" flavor="main" kernel_pin="":
    @{{ just }} build {{ image }} {{ tag }} {{ flavor }} 1 0 0 {{ kernel_pin }}

# Build Image with GHCR Flag
[group('Image')]
build-ghcr image="bluefin" tag="latest" flavor="main" kernel_pin="":
    #!/usr/bin/bash
    if [[ "${UID}" -gt "0" ]]; then
        echo "Must Run with sudo or as root..."
        exit 1
    fi
    {{ just }} build {{ image }} {{ tag }} {{ flavor }} 0 1 0 {{ kernel_pin }}

# Build Image for Pipeline:
[group('Image')]
build-pipeline image="bluefin" tag="latest" flavor="main" kernel_pin="":
    #!/usr/bin/bash
    ${SUDOIF} {{ just }} build {{ image }} {{ tag }} {{ flavor }} 1 1 1 {{ kernel_pin }}

# Rechunk Image
[group('Image')]
[private]
rechunk $image="bluefin" $tag="latest" $flavor="main" ghcr="0" pipeline="0":
    #!/usr/bin/bash

    echo "::group:: Rechunk Prep"
    set -eoux pipefail

    # Validate
    {{ just }} validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$({{ just }} image_name {{ image }} {{ tag }} {{ flavor }})

    # Check if image is already built
    ID=$(${PODMAN} images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        {{ just }} build "${image}" "${tag}" "${flavor}"
    fi

    # Load into Rootful Podman
    ID=$(${SUDOIF} ${PODMAN} images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" && ! ${PODMAN} =~ docker ]]; then
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp ${UID}@localhost::localhost/"${image_name}":"${tag}" root@localhost::localhost/"${image_name}":"${tag}"
        rm -rf "${COPYTMP}"
    fi

    # Prep Container
    CREF=$(${SUDOIF} ${PODMAN} create localhost/"${image_name}":"${tag}" bash)
    OLD_IMAGE=$(${SUDOIF} ${PODMAN} inspect $CREF | jq -r '.[].Image')
    OUT_NAME="${image_name}_build"
    MOUNT=$(${SUDOIF} ${PODMAN} mount "${CREF}")

    # Fedora Version
    fedora_version=$(${SUDOIF} ${PODMAN} inspect $CREF | jq -r '.[].Config.Labels["ostree.linux"]' | grep -oP 'fc\K[0-9]+')

    # Label Version
    VERSION=$(${SUDOIF} ${PODMAN} inspect $CREF | jq -r '.[].Config.Labels["org.opencontainers.image.version"]')

    # Git SHA
    SHA="dedbeef"
    if [[ -z "$(git status -s)" ]]; then
        SHA=$(git rev-parse HEAD)
    fi

    # Rest of Labels
    LABELS="
        io.artifacthub.package.deprecated=false
        io.artifacthub.package.keywords=bootc,fedora,bluefin,ublue,universal-blue
        io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4
        io.artifacthub.package.maintainers=[{\"name\": \"castrojo\", \"email\": \"jorge.castro@gmail.com\"}]
        io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/README.md
        org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
        org.opencontainers.image.license=Apache-2.0
        org.opencontainers.image.source=https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/Containerfile
        org.opencontainers.image.title=${image_name}
        org.opencontainers.image.url=https://projectbluefin.io
        org.opencontainers.image.vendor={{ repo_organization }}
        ostree.linux=$(${SUDOIF} ${PODMAN} inspect $CREF | jq -r '.[].Config.Labels["ostree.linux"]')
        containers.bootc=1
    "

    # Cleanup Space during Github Action
    if [[ "{{ ghcr }}" == "1" ]]; then
        base_image_name=silverblue-main
        if [[ "${tag}" =~ stable ]]; then
            tag="stable-daily"
        fi
        ID=$(${SUDOIF} ${PODMAN} images --filter reference=ghcr.io/{{ repo_organization }}/"${base_image_name}":${fedora_version} --format "{{ '{{.ID}}' }}")
        if [[ -n "$ID" ]]; then
            ${PODMAN} rmi "$ID"
        fi
    fi

    # Rechunk Container
    rechunker="{{ rechunker_image }}"

    echo "::endgroup::"
    echo "::group:: Prune"

    # Run Rechunker's Prune
    ${SUDOIF} ${PODMAN} run --rm \
        --pull=${PULL_POLICY} \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        "${rechunker}" \
        /sources/rechunk/1_prune.sh

    echo "::endgroup::"
    echo "::group:: Create ostree tree"

    # Run Rechunker's Create
    ${SUDOIF} ${PODMAN} run --rm \
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
    ${SUDOIF} ${PODMAN} unmount "$CREF"
    ${SUDOIF} ${PODMAN} rm "$CREF"
    ${SUDOIF} ${PODMAN} rmi "$OLD_IMAGE"

    echo "::endgroup::"
    echo "::group:: Rechunker"

    # Run Rechunker
    ${SUDOIF} ${PODMAN} run --rm \
        --pull=${PULL_POLICY} \
        --security-opt label=disable \
        --volume "$PWD:/workspace" \
        --volume "$PWD:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF=ghcr.io/ublue-os/"${image_name}":"${tag}" \
        --env OUT_NAME="$OUT_NAME" \
        --env LABELS="${LABELS}" \
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
    ${SUDOIF} find ${OUT_NAME} -type d -exec chmod 0755 {} \; || true
    ${SUDOIF} find ${OUT_NAME}* -type f -exec chmod 0644 {} \; || true

    if [[ "${UID}" -gt "0" ]]; then
        ${SUDOIF} chown "${UID}:${GROUPS}" -R "${PWD}"
    elif [[ -n "${SUDO_UID:-}" ]]; then
        chown "${SUDO_UID}":"${SUDO_GID}" -R "${PWD}"
    fi

    # Remove cache_ostree
    ${SUDOIF} ${PODMAN} volume rm cache_ostree

    echo "::endgroup::"

    # Pipeline Checks
    if [[ {{ pipeline }} == "1" && -n "${SUDO_USER:-}" ]]; then
        sudo -u "${SUDO_USER}" {{ just }} load-rechunk "${image}" "${tag}" "${flavor}"
        sudo -u "${SUDO_USER}" {{ just }} secureboot "${image}" "${tag}" "${flavor}"
    fi

# Load OCI into Podman Store
[group('Image')]
load-rechunk image="bluefin" tag="latest" flavor="main":
    #!/usr/bin/bash
    set -eou pipefail

    # Validate
    {{ just }} validate {{ image }} {{ tag }} {{ flavor }}

    # Image Name
    image_name=$({{ just }} image_name {{ image }} {{ tag }} {{ flavor }})

    # Load Image
    OUT_NAME="${image_name}_build"
    IMAGE=$(${PODMAN} pull oci:"${PWD}"/"${OUT_NAME}")
    ${PODMAN} tag ${IMAGE} localhost/"${image_name}":{{ tag }}

    # Cleanup
    rm -rf "${OUT_NAME}*"
    rm -f previous.manifest.json

# Run Container
[group('Image')]
run $image="bluefin" $tag="latest" $flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail

    # Validate
    {{ just }} validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$({{ just }} image_name {{ image }} {{ tag }} {{ flavor }})

    # Check if image exists
    ID=$(${PODMAN} images --filter reference=localhost/"${image_name}":"${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        {{ just }} build "$image" "$tag" "$flavor"
    fi

    # Run Container
    ${PODMAN} run -it --rm localhost/"${image_name}":"${tag}" bash

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
    set -eou pipefail

    # Get Cosign if Needed
    if [[ ! $(command -v cosign) ]]; then
        COSIGN_CONTAINER_ID=$(${SUDOIF} ${PODMAN} create cgr.dev/chainguard/cosign:latest bash)
        ${SUDOIF} ${PODMAN} cp "${COSIGN_CONTAINER_ID}":/usr/bin/cosign /usr/local/bin/cosign
        ${SUDOIF} ${PODMAN} rm -f "${COSIGN_CONTAINER_ID}"
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
    set -eou pipefail

    # Validate
    {{ just }} validate "${image}" "${tag}" "${flavor}"

    # Image Name
    image_name=$({{ just }} image_name ${image} ${tag} ${flavor})

    # Get the vmlinuz to check
    kernel_release=$(${PODMAN} inspect "${image_name}":"${tag}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$(${PODMAN} create "${image_name}":"${tag}" bash)
    ${PODMAN} cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz /tmp/vmlinuz
    ${PODMAN} rm "$TMP"

    # Get the Public Certificates
    curl --retry 3 -Lo /tmp/kernel-sign.der https://github.com/ublue-os/akmods/raw/main/certs/public_key.der
    curl --retry 3 -Lo /tmp/akmods.der https://github.com/ublue-os/akmods/raw/main/certs/public_key_2.der
    openssl x509 -in /tmp/kernel-sign.der -out /tmp/kernel-sign.crt
    openssl x509 -in /tmp/akmods.der -out /tmp/akmods.crt

    # Make sure we have sbverify
    CMD="$(command -v sbverify)"
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        ${PODMAN} run -dt \
            --entrypoint /bin/sh \
            --volume /tmp/vmlinuz:/tmp/vmlinuz:z \
            --volume /tmp/kernel-sign.crt:/tmp/kernel-sign.crt:z \
            --volume /tmp/akmods.crt:/tmp/akmods.crt:z \
            --name ${temp_name} \
            alpine:edge
        ${PODMAN} exec ${temp_name} apk add sbsigntool
        CMD="${PODMAN} exec ${temp_name} /usr/bin/sbverify"
    fi

    # Confirm that Signatures Are Good
    $CMD --list /tmp/vmlinuz
    returncode=0
    if ! $CMD --cert /tmp/kernel-sign.crt /tmp/vmlinuz || ! $CMD --cert /tmp/akmods.crt /tmp/vmlinuz; then
        echo "Secureboot Signature Failed...."
        returncode=1
    fi
    if [[ -n "${temp_name:-}" ]]; then
        ${PODMAN} rm -f "${temp_name}"
    fi
    exit "$returncode"

# Get Fedora Version of an image
[group('Utility')]
[private]
fedora_version image="bluefin" tag="latest" flavor="main" $kernel_pin="":
    #!/usr/bin/bash
    set -eou pipefail
    {{ just }} validate {{ image }} {{ tag }} {{ flavor }}
    if [[ ! -f /tmp/manifest.json ]]; then
        if [[ "{{ tag }}" =~ stable ]]; then
            # CoreOS does not uses cosign
            skopeo inspect --retry-times 3 docker://quay.io/fedora/fedora-coreos:stable > /tmp/manifest.json
        else
            skopeo inspect --retry-times 3 docker://ghcr.io/ublue-os/base-main:"{{ tag }}" > /tmp/manifest.json
        fi
    fi
    fedora_version=$(jq -r '.Labels["org.opencontainers.image.version"]' < /tmp/manifest.json | grep -oP '^[0-9]+')
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
    {{ just }} validate {{ image }} {{ tag }} {{ flavor }}
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
    WEEKLY="Tuesday"
    if [[ {{ ghcr }} == "0" ]]; then
        rm -f /tmp/manifest.json
    fi
    FEDORA_VERSION="$({{ just }} fedora_version '{{ image }}' '{{ tag }}' '{{ flavor }}' '{{ kernel_pin }}')"
    DEFAULT_TAG=$({{ just }} generate-default-tag {{ tag }} {{ ghcr }})
    IMAGE_NAME=$({{ just }} image_name {{ image }} {{ tag }} {{ flavor }})
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
    IMAGE=$(${PODMAN} inspect localhost/{{ image_name }}:{{ default_tag }} | jq -r .[].Id)
    ${PODMAN} untag localhost/{{ image_name }}:{{ default_tag }}

    # Tag Image
    for tag in {{ tags }}; do
        ${PODMAN} tag $IMAGE {{ image_name }}:${tag}
    done


    # Show Images
    ${PODMAN} images

# Examples:
#   > just retag-nvidia-on-ghcr stable-daily stable-daily-41.20250126.3 0
#   > just retag-nvidia-on-ghcr latest latest-41.20250228.1 0
#
# working_tag: The tag of the most recent known good image (e.g., stable-daily-41.20250126.3)
# stream:      One of latest, stable-daily, stable or gts
# dry_run:     Only print the skopeo commands instead of running them
#
# First generate a PAT with package write access (https://github.com/settings/tokens)
# and set $GITHUB_USERNAME and $GITHUB_PAT environment variables

# Retag images on GHCR
[group('Admin')]
retag-nvidia-on-ghcr working_tag="" stream="" dry_run="1":
    #!/bin/bash
    set -euxo pipefail
    skopeo="echo === skopeo"
    if [[ "{{ dry_run }}" -ne 1 ]]; then
        echo "$GITHUB_PAT" | podman login -u $GITHUB_USERNAME --password-stdin ghcr.io
        skopeo="skopeo"
    fi
    for image in bluefin-nvidia-open bluefin-dx-nvidia-open; do
      $skopeo copy docker://ghcr.io/ublue-os/${image}:{{ working_tag }} docker://ghcr.io/ublue-os/${image}:{{ stream }}
    done
