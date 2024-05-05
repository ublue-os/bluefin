#!/usr/bin/bash

image=$1
target=$2
version=$3

# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

container_mgr=$(just _container_mgr)
tag=$(just _tag "${image}" "${target}")
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

run_cmd="run -it --rm --privileged"
if [[ "${container_mgr}" =~ "podman" ]]; then
    run_cmd="${run_cmd} --userns=keep-id"
fi
run_cmd="${run_cmd} -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group"

temp_shadow=$(mktemp)
cat "${project_root}"/scripts/etc-shadow >> "${temp_shadow}"
echo "${USER}:\$y\$j9T\$uQkZGY3QpPmddmtkavB0Z/\$c2rwYgbGPq6lcdpTeof0S7YjOGgfKaKXWxoKy3HjKhC:19816:0:99999:7:::" >> "${temp_shadow}"
run_cmd="${run_cmd} -v ${temp_shadow}:/etc/shadow"

home_mount=/home
if [[ -n "$(readlink ${home_mount})" ]]; then
    home_mount=/$(readlink /home)
fi

run_cmd="${run_cmd} -v ${home_mount}:/var/home"
echo "$run_cmd"
#shellcheck disable=SC2086
$container_mgr ${run_cmd} localhost/"${tag}":"${version}" /usr/lib/systemd/systemd rhgb --system 

rm -f "${temp_shadow}"