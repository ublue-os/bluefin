#!/usr/bin/bash
# shellcheck disable=SC1091,SC2154
# Shellcheck SC1091 => sourcing /usr/share/ublue-os/bluefin-cli/known-containers
# Shellcheck SC2154 => known containers Associative Array declared in above source

# Container Name and Target Name for Quadlet
name=$1

# Source Known Containers used with ptyxis profiles 
. /usr/share/ublue-os/bluefin-cli/known-containers
if test -z "${known_container[$name]}"; then
    notify-send "Unknown Container $name... Bailing Out..."
    exit 1
fi

# Host isn't a container.
if test "${name}" == "Host"; then

# Start Ptyxis
    ptyxis --tab-with-profile="${known_container[$name]}" --new-window

else

# Check if quadlet target is enabled
    if ! eval systemctl --user --quiet is-enabled "${name}".target; then
        notify-send "Starting ${name}, please be patient"
        systemctl --user enable --now "${name}".target
    fi

# Check if quadlet is running
    if ! eval systemctl --user --quiet is-active "${name}".service; then
        notify-send "Restarting ${name}, please be patient"
        systemctl --user restart "${name}".service
        # Give the Quadlet a second to startup
        sleep 1
    fi

# Final Check... If the container doesn't exist bail out.
    if ! grep -q "${name}" <<< "$(podman ps -a --no-trunc --format "{{.Names}}")"; then
        notify-send "${name} not created properly... Bailing Out..."
        exit 1
    fi

# Start Ptyxis
    ptyxis --tab-with-profile="${known_container[$name]}" --new-window
fi

