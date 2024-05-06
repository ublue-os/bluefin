#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi

# Get inputs
image=$1
target=$2
version=$3

# Set image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/scripts/get-defaults.sh"

# Get items
container_mgr=$(just _container_mgr)
if "${container_mgr}" info | grep Root | grep -q /home; then
    echo "Cannot run Graphical Session wiht rootless container..."
    secs=5
    while [ $secs -gt 0 ]
    do
        printf "\r\033[KWaiting %.d seconds." $((secs--))
        sleep 1
    done
fi
tag=$(just _tag "${image}" "${target}")

# Check to see if image exists, build it if it doesn't
ID=$(${container_mgr} images --filter reference=localhost/"${tag}":"${version}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

# Set workspace variable
workspace=${project_root}
if [[ -f /.dockerenv ]]; then
    workspace=${LOCAL_WORKSPACE_FOLDER}
fi
workspace_files=${workspace}/scripts/files

# Start building run command
run_cmd="run -it --rm --privileged"

# Sharable /tmp
run_cmd="${run_cmd} -v /tmp:/tmp:rslave"

# Mount in $HOME.
run_cmd="${run_cmd} -v /var/home"
mkdir -p "${project_root}"/scripts/files/home/ublue-os
run_cmd="${run_cmd} -v ${workspace_files}/home/ublue-os:/var/home/ublue-os:rslave"

# Mount in VAR
run_cmd="${run_cmd} -v /var:/var:rslave"

# Blank out items
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/auditd.service"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.path"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.service"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.socket"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/rtkit-daemon.service"
run_cmd="${run_cmd} -v /var/log/journal"
run_cmd="${run_cmd} -v /sys/fs/selinux"

# Mount in passwd/group for user account to work
run_cmd="${run_cmd} -v ${workspace_files}/etc/passwd:/etc/passwd:ro -v ${workspace_files}/etc/group:/etc/group:ro -v ${workspace_files}/etc/shadow:/etc/shadow:ro"

# Set Hostname
run_cmd="{run_cmd} -v ${workspace_files}/etc/hostname:/etc/hostname"

# Boot the container
#shellcheck disable=SC2086
"${container_mgr}" $run_cmd localhost/"${tag}":"${version}" /usr/lib/systemd/systemd rhgb --system 

# Clean Up
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi
rm -rf "${project_root}/scripts/files/home/ublue-os/*"