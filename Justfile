default_image := "bluefin"
default_target := "base"
gts := "39"
latest := "40"

_build image=default_image target=default_target version=gts:
	#!/usr/bin/bash
	set -exuo pipefail
	container_mgr=$([ $(command -v podman) ] && echo podman || echo docker)
	base_image=$([[ {{image}} =~ "bluefin" ]] && echo "silverblue" || echo "kinoite")
	echo $base_image
	$container_mgr build -f Containerfile --build-arg="AKMODS_FLAVOR=main" --build-arg="BASE_IMAGE_NAME=${base_image}" --build-arg="SOURCE_IMAGE=${base_image}-main" --build-arg="FEDORA_MAJOR_VERSION={{version}}" -t localhost/{{image}}-{{target}}:{{version}} --target {{target}} .

_run image=default_image target=default_target version=gts:
	#!/usr/bin/bash
	set -euo pipefail
	container_mgr=$([ $(command -v podman) ] && echo podman || echo docker)
	$container_mgr run -it --rm localhost/{{image}}-{{target}}:{{version}}

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