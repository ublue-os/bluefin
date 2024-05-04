gts := "39"
latest := "40"

_default:
	just --list

_container_mgr:
	#!/usr/bin/bash
	set -euo pipefail
	if [[ $(command -v podman) ]]; then
		echo podman
	elif [[ $(command -v docker) ]]; then
		echo docker
	elif [[ $(command -v podman-remote) ]];then
		echo podman-remote
	else
		exit 1
	fi

_base_image image:
	#!/usr/bin/bash
	set -euo pipefail
	if [[ {{image}} =~ "bluefin" ]]; then
		echo silverblue
	elif [[ {{image}} =~ "aurora" ]]; then
		echo kinoite
	else
		exit 1
	fi

_tag image target:
	#!/usr/bin/bash
	set -euo pipefail
	if [[ {{target}} =~ "base" ]]; then
		echo {{image}}-build
	elif [[ {{target}} =~ "dx" ]]; then
		echo "{{image}}-{{target}}-build"
	fi

# Build Image
build image="" target="" version="":
	#!/usr/bin/bash
	set -euo pipefail
	image={{image}}
	target={{target}}
	version={{version}}
	if [[ ${image} =~ "-dx" ]]; then
		image=$(cut -d - -f 1 <<< ${image}) 
		version=${target}
		target="dx"
	fi
	if [[ -z "${image}" ]]; then
		image="bluefin"
	fi
	if [[ -z "${target}" ]]; then
		target="base"
	elif [[ ${target} =~ ^[0-9]+$ ]]; then
		version=${target}
		target="base"
	fi
	if [[ -z "${version}" ]]; then
		if [[ "${image}" =~ "bluefin" ]]; then
			version={{gts}}
		elif [[ "${image}" =~ "aurora" ]]; then
			version={{latest}}
		fi
	elif [[ ${version} =~ "gts" ]]; then
		version={{gts}}
	elif [[ ${version} =~ "latest" ]]; then
		version={{latest}}
	fi
	container_mgr=$(just _container_mgr)
	base_image=$(just _base_image ${image})
	tag=$(just _tag ${image} ${target})
	$container_mgr build -f Containerfile --build-arg="AKMODS_FLAVOR=main" --build-arg="BASE_IMAGE_NAME=${base_image}" --build-arg="SOURCE_IMAGE=${base_image}-main" --build-arg="FEDORA_MAJOR_VERSION=${version}" -t localhost/${tag}:${version} --target ${target} .

# Run image
run image="" target="" version="":
	#!/usr/bin/bash
	set -euo pipefail
	image={{image}}
	target={{target}}
	version={{version}}
	if [[ ${image} =~ "-dx" ]]; then
		image=$(cut -d - -f 1 <<< ${image}) 
		version=${target}
		target="dx"
	fi
	if [[ -z "${image}" ]]; then
		image="bluefin"
	fi
	if [[ -z "${target}" ]]; then
		target="base"
	elif [[ ${target} =~ ^[0-9]+$ ]]; then
		version=${target}
		target="base"
	fi
	if [[ -z "${version}" ]]; then
		if [[ "${image}" =~ "bluefin" ]]; then
			version={{gts}}
		elif [[ "${image}" =~ "aurora" ]]; then
			version={{latest}}
		fi
	elif [[ ${version} =~ "gts" ]]; then
		version={{gts}}
	elif [[ ${version} =~ "latest" ]]; then
		version={{latest}}
	fi
	container_mgr=$(just _container_mgr)
	tag=$(just _tag ${image} ${target})
	$container_mgr run -it --rm localhost/${tag}:${version} /usr/bin/bash

# Remove built images
clean:
	#!/usr/bin/bash
	set -euox pipefail
	container_mgr=$(just _container_mgr)
	ID=$(${container_mgr} images --filter "reference=localhost/bluefin*-build" --filter "reference=localhost/aurora*-build" --format {{"{{.ID}}"}})
	xargs -I {} ${container_mgr} image rm {} <<< $ID

# List Built Images
list-images:
	#!/usr/bin/bash
	set -euo pipefail
	container_mgr=$(just _container_mgr)
	${container_mgr} images --filter "reference=localhost/bluefin*-build" --filter "reference=localhost/aurora*-build"
	
# Build and Run Bluefin
bluefin:
	just build bluefin base {{gts}} && \
	just run bluefin base {{gts}}

# Build and Run Bluefin-DX
bluefin-dx:
	just build bluefin dx {{gts}} && \
	just run bluefin dx {{gts}}

# Build and Run Bluefin Latest
bluefin-latest:
	just build bluefin base {{latest}} && \
	just run bluefin base {{latest}}

# Build and Run Bluefin-DX Latest
bluefin-dx-latest:
	just build bluefin dx {{latest}} && \
	just run bluefin dx {{latest}}

# Build and Run Aurora
aurora:
	just build aurora base {{latest}} && \
	just run aurora base {{latest}}

# Build and Run Aurora-DX
aurora-dx:
	just build aurora dx {{latest}} && \
	just run aurora dx {{latest}}