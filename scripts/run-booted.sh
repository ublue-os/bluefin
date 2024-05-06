#!/usr/bin/bash

# Get inputs
image=$1
target=$2
version=$3

# Set image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get items
container_mgr=$(just _container_mgr)
tag=$(just _tag "${image}" "${target}")

# Check to see if image exists, build it if it doesn't
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

# Start building run command
run_cmd="run -it --rm --privileged"

# Podman needs --userns=keep-id
# if [[ "${container_mgr}" =~ "podman" ]]; then
#     run_cmd="${run_cmd} --userns=keep-id"
# fi

# Mount in passwd/group for user account to work
run_cmd="${run_cmd} -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group"

# Make a temporary etc/shadow that the user can read.
# temp_shadow=$(mktemp)
# cat "${project_root}"/scripts/files/etc-shadow >> "${temp_shadow}"
# # Set Add $USER and password to ublue-os
# echo "${USER}:\$y\$j9T\$uQkZGY3QpPmddmtkavB0Z/\$c2rwYgbGPq6lcdpTeof0S7YjOGgfKaKXWxoKy3HjKhC:19816:0:99999:7:::" >> "${temp_shadow}"
# run_cmd="${run_cmd} -v ${temp_shadow}:/etc/shadow"
run_cmd="${run_cmd} -v /etc/shadow:/etc/shadow"

# Mount in VAR
run_cmd="${run_cmd} -v /var:/var"

# Mount in $HOME.
home_mount=/home
# if [[ -n "$(readlink ${home_mount})" ]]; then
#     home_mount=/$(readlink /home)
# fi
run_cmd="${run_cmd} -v ${home_mount}:/var/home"

# Boot the container
#shellcheck disable=SC2086
"${container_mgr}" $run_cmd localhost/"${tag}":"${version}" /usr/lib/systemd/systemd rhgb --system 

exit 0
#Remove temporary etc-shadow
# rm -f "${temp_shadow}"