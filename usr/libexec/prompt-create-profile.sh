#!/usr/bin/bash

# create a Prompt profile using dconf given the guid of the instance
# $1 = name

# dconf read /org/gnome/Prompt/Profiles/d092b3519698570a3252762c658f7629/
# /org/gnome/Prompt/Profiles/d092b3519698570a3252762c658f7629/custom-command
#   'blincus shell myubuntu'
# /org/gnome/Prompt/Profiles/d092b3519698570a3252762c658f7629/label
#   'myubuntu'
# /org/gnome/Prompt/Profiles/d092b3519698570a3252762c658f7629/login-shell
#   true
# /org/gnome/Prompt/Profiles/d092b3519698570a3252762c658f7629/use-custom-command
#   true

# if dconf doesn't exist, just return
if ! command -v dconf >/dev/null; then
    return
fi

# shellcheck disable=SC2001
gen_uuid() {
	uuid="$(cat /proc/sys/kernel/random/uuid)"
	echo "$uuid" | sed 's/-//g'
}

guid=$(gen_uuid)
name="$1"
palette="$2"

profile="/org/gnome/Prompt/Profiles/${guid}/"

dconf write "${profile}custom-command" "'sh -c \"[ ! -e /run/.containerenv ] && [ ! -e /run/.dockerenv ] && distrobox enter ${name} || ${SHELL}\"'"
dconf write "${profile}label" "'${name}'"
dconf write "${profile}use-custom-command" "true"
if test -n "$palette"; then
	dconf write "${profile}palette" "'${palette}'"
elif test "$name" = "bluefin-cli"; then
	dconf write "${profile}palette" "'catppuccin-dynamic'"
fi

/usr/libexec/prompt-add-profile.sh "$guid"
