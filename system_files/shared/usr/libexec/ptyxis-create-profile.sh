#!/usr/bin/bash

# create a Ptyxis profile using dconf given the guid of the instance
# $1 = name

# dconf read /org/gnome/Ptyxis/Profiles/d092b3519698570a3252762c658f7629/
# /org/gnome/Ptyxis/Profiles/d092b3519698570a3252762c658f7629/custom-command
#   'blincus shell myubuntu'
# /org/gnome/Ptyxis/Profiles/d092b3519698570a3252762c658f7629/label
#   'myubuntu'
# /org/gnome/Ptyxis/Profiles/d092b3519698570a3252762c658f7629/login-shell
#   true
# /org/gnome/Ptyxis/Profiles/d092b3519698570a3252762c658f7629/use-custom-command
#   true

# shellcheck disable=SC1091
. /usr/share/ublue-os/bluefin-cli/known-ptyxis-profiles

# if dconf doesn't exist, just return
if ! command -v dconf >/dev/null; then
    exit 0
fi


# shellcheck disable=SC2001
gen_uuid() {
	uuid="$(cat /proc/sys/kernel/random/uuid)"
	echo "$uuid" | sed 's/-//g'
}

name="$1"
default="$2"
palette="$3"

# shellcheck disable=2154
for check in "${!known_profile[@]}"; do
	if test "$check" = "$name"; then
		guid=${known_profile[$check]}
	fi
done

if test -z "$guid"; then
	guid=$(gen_uuid)
fi

default_guid=$(dconf read /org/gnome/Ptyxis/default-profile-uuid)
default_guid=${default_guid:1:-1}

# If default profile is trying to be made, just exit
if test "$guid" = "$default_guid"; then
	exit 0	
fi

if test -z "$default"; then
    make_default=0
elif test "$default" = "default" || test "$default" -eq 1; then
    make_default=1
fi

# Write the default value if specified
if test "$make_default" -eq 1; then
    dconf write /org/gnome/Ptyxis/default-profile-uuid "'${guid}'"
fi

profile="/org/gnome/Ptyxis/Profiles/${guid}/"
opacity=$(dconf read /org/gnome/Ptyxis/Profiles/"${default_guid}"/opacity)

if test "$name" = "Host"; then
	dconf write "${profile}label" "'${name}'"
fi

if test -n "$opacity"; then
	dconf write "${profile}opacity" "'${opacity}'"
fi

if test -n "$palette"; then
	dconf write "${profile}palette" "'${palette}'"
fi

/usr/libexec/ptyxis-add-profile.sh "$guid"
