default_image := "bluefin"
default_target := "base"
gts := "39"
latest := "40"

_container_mgr:
	#!/usr/bin/bash
	set -euo pipefail
	if [[ $(command -v podman) ]]; then
		echo podman
	elif [[ $(command -v docker) ]]; then
		echo docker
	elif [[ $(command -v podman-remote) ]];then
		echo podman-remote
	fi

_build image=default_image target=default_target version=gts:
	#!/usr/bin/bash
	set -euo pipefail
	container_mgr=$(just _container_mgr)
	if [[ {{image}} =~ "bluefin" ]]; then
		base_image="silverblue"
	elif [[ {{image}} =~ "aurora" ]]; then
		base_image="kinoite"
	else
		echo "Unknown image. Exiting"
		exit 1
	fi
	$container_mgr build -f Containerfile --build-arg="AKMODS_FLAVOR=main" --build-arg="BASE_IMAGE_NAME=${base_image}" --build-arg="SOURCE_IMAGE=${base_image}-main" --build-arg="FEDORA_MAJOR_VERSION={{version}}" -t localhost/{{image}}-{{target}}:{{version}} --target {{target}} .

_run image=default_image target=default_target version=gts:
	#!/usr/bin/bash
	set -euo pipefail
	container_mgr=$(just _container_mgr)
	$container_mgr run -it --rm localhost/{{image}}-{{target}}:{{version}} /usr/bin/bash --login

bluefin:
	just _build && just _run

bluefin-dx:
	just _build {{default_image}} dx {{gts}} && \
	just _run {{default_image}} dx {{gts}}

bluefin-latest:
	just _build {{default_image}} {{default_target}} {{latest}} && \
	just _run {{default_image}} {{default_target}} {{latest}}

bluefin-dx-latest:
	just _build {{default_image}} dx {{latest}} && \
	just _run {{default_image}} dx {{latest}}

aurora:
	just _build aurora {{default_target}} {{latest}} && \
	just _run aurora {{default_target}} {{latest}}

aurora-dx:
	just _build aurora dx {{latest}} && \
	just _run aurora dx {{latest}}