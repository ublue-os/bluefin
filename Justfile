export project_root := `git rev-parse --show-toplevel`
export git_branch := ` git branch --show-current`

alias run := run-container

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
    	just --unstable --fmt --check -f $file 
    done
    echo "Checking syntax: ${project_root}/Justfile"
    just --unstable --fmt --check -f ${project_root}/Justfile

# Fix Just Syntax
just-fix:
    #!/usr/bin/bash
    find "${project_root}" -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: ${project_root}/Justfile"
    just --unstable --fmt -f ${project_root}/Justfile || { exit 1; }

# Build Image
build image="" target="" version="":
    @{{ project_root }}/scripts/build-image.sh {{ image }} {{ target }} {{ version }}

# Run image
run-container image="" target="" version="":
    @{{ project_root }}/scripts/run-image.sh {{ image }} {{ target }} {{ version }}

# # Run Booted Image Session w/ Guest
# run-booted-guest image="" target="" version="":
#     @{{ project_root }}/scripts/run-booted-guest.sh {{ image }} {{ target }} {{ version }}
# # Run Booted Image Session w/ mounted in $USER and $HOME
# run-booted-home image="" target="" version="":
#     @{{ project_root }}/scripts/run-booted-home.sh {{ image }} {{ target }} {{ version }}

# Create ISO from local dev build image
build-iso image="" target="" version="":
    @{{ project_root }}/scripts/build-iso.sh {{ image }} {{ target }} {{ version }}

# Create ISO from local dev build image - use build-container-installer:main
build-iso-installer-main image="" target="" version="":
    @{{ project_root }}/scripts/build-iso-installer-main.sh {{ image }} {{ target }} {{ version }}

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
    echo "                                                                              "
    echo "Helper scripts are in 'project_root/scripts'.                                 "
    echo "                                                                              "
    echo "Modify the 'devcontainer.json' in 'project_root/.devcontainer' to support     "
    echo "Running the devcontainer with podman or docker                                "
    echo "Manually specify container manager with '$CONTAINER_MGR' enviornment variable "
    echo "                                                                              "
    just --list

# Build Bluefin GTS
bluefin: (build "bluefin" "base" "gts")

# Build Bluefin-DX GTS
bluefin-dx: (build "bluefin" "dx" "gts")

# Build Bluefin GTS ISO
bluefin-iso: (build-iso "bluefin" "base" "gts")

# Build Bluefin-DX GTS ISO
bluefin-dx-iso: (build-iso "bluefin" "dx" "gts")

# Build Aurora
aurora: (build "aurora" "base" "stable")

# Builed Aurora-DX
aurora-dx: (build "aurora" "dx" "stable")

# Build Aurora ISO
aurora-iso: (build-iso "aurora" "base" "stable")

# Builed Aurora-DX ISO
aurora-dx-iso: (build-iso "aurora" "dx" "stable")
