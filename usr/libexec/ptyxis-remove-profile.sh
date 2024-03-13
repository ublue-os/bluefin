#!/usr/bin/bash
# ensure that the ptyxis profiles for deleted instances are removed

# if dconf doesn't exist, just return
if ! command -v dconf >/dev/null; then
    return
fi

# Cleanup any stale profiles
for i in $(dconf list /org/gnome/Ptyxis/Profiles/); do
    i=${i:0:-1}
    [[ $(dconf read /org/gnome/Ptyxis/profile-uuids) =~ $i ]] || dconf reset -f "/org/gnome/Ptyxis/Profiles/${i}/"
done

name="$1"

# Read the current value of the array
CURRENT_VALUE=$(dconf read /org/gnome/Ptyxis/profile-uuids)

# remove the leading and trailing brackets
CURRENT_VALUE=${CURRENT_VALUE:1:-1}

# remove any spaces
CURRENT_VALUE=${CURRENT_VALUE// /}

# split the string into an array
IFS=',' read -r -a array <<<"$CURRENT_VALUE"

# Get Default
DEFAULT_VALUE=$(dconf read /org/gnome/Ptyxis/default-profile-uuid)

# loop through the array and remove any that don't exist
for i in "${!array[@]}"; do
    guid=${array[i]}

    # remove single quotes from guid
    guid=${guid//\'/}

    #echo "Checking profile for $(red $guid)"
    profile="/org/gnome/Ptyxis/Profiles/${guid}/"

    ublue_os=$(dconf read "${profile}ublue-os")
    label=$(dconf read "${profile}label")
    label=${label:1:-1}

    if test "$ublue_os" = "true"; then
        # Don't delete the profile if it's the default or if it's enabled
        if ! test "$DEFAULT_VALUE" = "$guid" && test "$name" = "$label" && ! systemctl --user --quiet is-enabled "${name}".target; then
            dconf reset -f "${profile}"
            # remove the guid from the array
            unset 'array[i]'
            # join the array back into a string
            UPDATED_VALUE=$(printf "%s," "${array[@]}")

            # remove the trailing comma
            UPDATED_VALUE=${UPDATED_VALUE%?}

            # add the leading and trailing brackets
            UPDATED_VALUE="[$UPDATED_VALUE]"

            # Write the updated array back to dconf
            dconf write /org/gnome/Ptyxis/profile-uuids "$UPDATED_VALUE"
        fi
    fi
done
