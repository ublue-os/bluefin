#!/usr/bin/bash
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi
if [[ -z ${git_branch} ]]; then
    git_branch=$(git branch --show-current)
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
tag=$(just _tag "${image}" "${target}")

# Graphical Warning
if "${container_mgr}" info | grep Root | grep -q /home; then
    echo "Cannot run Graphical Session with rootless container..."
    secs=5
    while [ $secs -gt 0 ]
    do
        printf "\r\033[KWaiting %.d seconds." $((secs--))
        sleep 1
    done
fi

# Check to see if image exists, build it if it doesn't
ID=$(${container_mgr} images --filter reference=localhost/"${tag}:${version}-${git_branch}" --format "{{.ID}}")
if [[ -z ${ID} ]]; then
    just build "${image}" "${target}" "${version}"
fi

# Start building run command
run_cmd+=(run -it --rm --privileged)

# Mount in passwd/group for user account to work
run_cmd+=(-v /etc/passwd:/etc/passwd:ro)
run_cmd+=(-v /etc/group:/etc/group:ro)
run_cmd+=(-v /etc/shadow:/etc/shadow:ro)

# Mount in System Flatpaks and TMP
run_cmd+=(-v /tmp:/tmp:rslave)
run_cmd+=(-v /var/lib/flatpak:/var/lib/flatpak:rslave)

# Mount in $HOME.
home_location=/home
if [[ -L /home ]]; then
    home_location=/$(readlink /home)
fi
run_cmd+=(-v "${home_location}":/var/home:rslave)

# Blank out items
run_cmd+=(-v /dev/null:/usr/lib/systemd/system/auditd.service)
run_cmd+=(-v /dev/null:/usr/lib/systemd/system/cups.path)
run_cmd+=(-v /dev/null:/usr/lib/systemd/system/cups.service)
run_cmd+=(-v /dev/null:/usr/lib/systemd/system/cups.socket)
run_cmd+=(-v /dev/null:/usr/lib/systemd/system/rtkit-daemon.service)
run_cmd+=(-v /var/log/journal)
run_cmd+=(-v /sys/fs/selinux)

# Host Network Option
if [[ -n ${HOST_NETWORK} ]]; then
    run_cmd+=(--network host)
    run_cmd+=(-v /etc/NetworkManager:/etc/NetworkManager)
    run_cmd+=(-v /etc/hosts:/etc/hosts)
    run_cmd+=(-v /etc/resolv.conf:/etc/resolv.conf)
fi

# Boot the container
"$container_mgr" "${run_cmd[@]}" "localhost/${tag}:${version}" /sbin/init

exit 0
