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

# Start building run command
run_cmd="run -it --rm --privileged"

# Mount in passwd/group for user account to work
run_cmd="${run_cmd} -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /etc/shadow:/etc/shadow:ro"

# Mount in VAR
run_cmd="${run_cmd} -v /var:/var:rslave"

# Mount in $HOME.
home_location=/home
if [[ -L /home ]]; then
    home_location=/$(readlink /home)
fi
run_cmd="${run_cmd} -v ${home_location}:/var/home:rslave"

# Sharable /tmp
run_cmd="${run_cmd} -v /tmp:/tmp:rslave"

# Blank out items
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/auditd.service"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.path"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.service"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/cups.socket"
run_cmd="${run_cmd} -v /dev/null:/usr/lib/systemd/system/rtkit-daemon.service"
run_cmd="${run_cmd} -v /var/log/journal"
run_cmd="${run_cmd} -v /sys/fs/selinux"

# Set workspace variable
workspace=${project_root}
if [[ -f /.dockerenv ]]; then
    workspace=${LOCAL_WORKSPACE_FOLDER}
fi
workspace_files=${workspace}/scripts/files
# Set Hostname
run_cmd="{run_cmd} -v ${workspace_files}/etc/hostname:/etc/hostname"

# Boot the container
#shellcheck disable=SC2086
"${container_mgr}" $run_cmd localhost/"${tag}":"${version}" /usr/lib/systemd/systemd rhgb --system 

exit 0