export project_root := `git rev-parse --show-toplevel`
export gts := "39"
export latest := "40"

_default:
	@just help

_container_mgr:
	@{{project_root}}/scripts/container_mgr.sh

_base_image image:
	@{{project_root}}/scripts/base-image.sh {{image}}

_tag image target:
	@{{project_root}}/scripts/make-tag.sh {{image}} {{target}}

# Build Image
build image="" target="" version="":
	@{{project_root}}/scripts/build-image.sh {{image}} {{target}} {{version}}

# Run image
run image="" target="" version="":
	@{{project_root}}/scripts/run-image.sh {{image}} {{target}} {{version}}

# Run Booted Image Session; User = $USER, Password = ublue-os
run-booted image="" target="" version="":
	@{{project_root}}/scripts/run-booted.sh {{image}} {{target}} {{version}}

# Create ISO; DevContainer requires Docker. Host requires Root Privileges
build-iso image="" target="" version="":
	@{{project_root}}/scripts/build-iso.sh {{image}} {{target}} {{version}}

# Remove built images, build files, and ISOs
clean:
	@{{project_root}}/scripts/cleanup.sh

# List Built Images
list-images:
	@{{project_root}}/scripts/list-images.sh

[private]
help:
	#!/usr/bin/bash
	echo "                                                                              "
	echo "These are helper scripts for building and testing development images          "
	echo "                                                                              "
	echo "You can run dev images either in 'booted like' setup with 'just run-booted'   "
	echo "Or in a more stripped down version with 'just run'                            "
	echo "Specify which image you wish to build and run by name.                        "
	echo "Example: 'just run aurora' -> runs aurora without systemd                     "
	echo "Example: 'just run-booted bluefin-dx' -> runs bluefin-dx with systemd         "
	echo "                                                                              "
	echo "Helper scripts are in 'project_root/scripts'.                                 "
	echo "                                                                              "
	echo "Modify the 'devcontainer.json' in 'project_root/.devcontainer' to support     "
	echo "Running the devcontainer with podman or docker                                "
	echo "Manually specify container manager with '$CONTAINER_MGR' enviornment variable "
	echo "                                                                              "
	just --list
	
# Run Bluefin - Build if not already built
bluefin: (run "bluefin" "base" "{{gts}}")

# Run Bluefin-DX - Build if not already built
bluefin-dx: (run "bluefin" "dx" "{{gts}}")

# Run Bluefin Latest - Build if not already built
bluefin-latest: (run "bluefin" "base" "{{latest}}")

# Run Bluefin-DX Latest - Build if not already built
bluefin-dx-latest: (run "bluefin" "dx" "{{latest}}")

# Run Aurora - Build if not already built
aurora: (run "aurora" "base" "{{latest}}")

# Run Aurora-DX - Build if not already built
aurora-dx: (run "aurora" "dx" "{{latest}}")
