export project_root := `git rev-parse --show-toplevel`
export gts := "39"
export latest := "40"

alias run := run-booted-guest

_default:
    @just help

_container_mgr:
    @{{ project_root }}/scripts/container_mgr.sh

_base_image image:
    @{{ project_root }}/scripts/base-image.sh {{ image }}

_tag image target:
    @{{ project_root }}/scripts/make-tag.sh {{ image }} {{ target }}

# Check Just Syntax
just-check:
    #!/usr/bin/bash
    find "${project_root}" -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file || { exit 1; }
    done
    just --unstable --fmt --check -f ${project_root}/Justfile || { exit 1; }

# Fix Just Syntax
[private]
just-fix:
    #!/usr/bin/bash
    find "${project_root}" -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file || { exit 1; }
    done
    just --unstable --fmt -f ${project_root}/Justfile || { exit 1; }

# Build Image
build image="" target="" version="":
    @{{ project_root }}/scripts/build-image.sh {{ image }} {{ target }} {{ version }}

# Run image
run-container image="" target="" version="":
    @{{ project_root }}/scripts/run-image.sh {{ image }} {{ target }} {{ version }}

# Run Booted Image Session w/ Guest
run-booted-guest image="" target="" version="":
    @{{ project_root }}/scripts/run-booted-guest.sh {{ image }} {{ target }} {{ version }}

# Run Booted Image Session w/ mounted in $USER and $HOME
run-booted-home image="" target="" version="":
    @{{ project_root }}/scripts/run-booted-home.sh {{ image }} {{ target }} {{ version }}

# Create ISO from local dev build image
build-iso image="" target="" version="":
    @{{ project_root }}/scripts/build-iso.sh {{ image }} {{ target }} {{ version }}

# Run ISO from local dev build image
run-iso image="" target="" version="":
    @{{ project_root }}/scripts/run-iso.sh {{ image }} {{ target }} {{ version }}

# Create ISO from currenct ghcr image
build-iso-ghcr image="" target="" version="":
    @{{ project_root }}/scripts/build-iso-ghcr.sh {{ image }} {{ target }} {{ version }}

# Clean Directory. Remove ISOs and Build Files
clean:
    @{{ project_root }}/scripts/cleanup-dir.sh

# Remove built images
clean-images:
    @{{ project_root }}/scripts/cleanup-images.sh

# List Built Images
list-images:
    @{{ project_root }}/scripts/list-images.sh

[private]
help:
    #!/usr/bin/bash
    echo "                                                                              "
    echo "These are helper scripts for building and testing development images          "
    echo "                                                                              "
    echo "You can run dev images either in 'booted like' setup with 'just run-booted'   "
    echo "Or in a more stripped down version with 'just run'                            "
    echo "Specify which image you wish to build and run by name.                        "
    echo "Example: 'just run-container aurora' -> runs aurora without systemd           "
    echo "Example: 'just run bluefin-dx' -> runs bluefin-dx with systemd                "
    echo "                                                                              "
    echo "Helper scripts are in 'project_root/scripts'.                                 "
    echo "                                                                              "
    echo "Modify the 'devcontainer.json' in 'project_root/.devcontainer' to support     "
    echo "Running the devcontainer with podman or docker                                "
    echo "Manually specify container manager with '$CONTAINER_MGR' enviornment variable "
    echo "                                                                              "
    just --list

# Build Bluefin
bluefin: (build "bluefin" "base" "{{gts}}")

# Build Bluefin-DX
bluefin-dx: (build "bluefin" "dx" "{{gts}}")

# Build Bluefin Latest
bluefin-latest: (build "bluefin" "base" "{{latest}}")

# Build Bluefin-DX Latest
bluefin-dx-latest: (build "bluefin" "dx" "{{latest}}")

# Build Aurora
aurora: (build "aurora" "base" "{{latest}}")

# Builed Aurora-DX
aurora-dx: (build "aurora" "dx" "{{latest}}")

# Build Bluefin-ISO
bluefin-iso: (build-iso "bluefin" "base" "{{gts}}")

# Build Bluefin-DX-ISO
bluefin-dx-iso: (build-iso "bluefin" "dx" "{{gts}}")

# Build Bluefin Latest-ISO
bluefin-latest-iso: (build-iso "bluefin" "base" "{{latest}}")

# Build Bluefin-DX Latest-ISO
bluefin-dx-latest-iso: (build-iso "bluefin" "dx" "{{latest}}")

# Build Aurora-ISO
aurora-iso: (build-iso "aurora" "base" "{{latest}}")

# Builed Aurora-DX-ISO
aurora-dx-iso: (build-iso "aurora" "dx" "{{latest}}")
