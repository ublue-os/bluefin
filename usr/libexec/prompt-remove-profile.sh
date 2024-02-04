#!/usr/bin/bash
# ensure that the prompt profiles for deleted instances are removed

# if dconf doesn't exist, just return
if ! command -v dconf >/dev/null; then
    return
fi

name="$1"

# Read the current value of the array
CURRENT_VALUE=$(dconf read /org/gnome/Prompt/profile-uuids)

# remove the leading and trailing brackets
CURRENT_VALUE=${CURRENT_VALUE:1:-1}

# remove any spaces
CURRENT_VALUE=${CURRENT_VALUE// /}

# split the string into an array
IFS=',' read -r -a array <<<"$CURRENT_VALUE"

# loop through the array and remove any that don't exist
for i in "${!array[@]}"; do
    guid=${array[i]}

    # remove single quotes from guid

    guid=${guid//\'/}

    #echo "Checking profile for $(red $guid)"
    profile="/org/gnome/Prompt/Profiles/${guid}/"

    custom_shell=$(dconf read "${profile}custom-command")

    if [[ $custom_shell == *"[ ! -e /run/.containerenv ] && [ ! -e /run/.dockerenv ] && distrobox enter ${name}"* ]]; then
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
        dconf write /org/gnome/Prompt/profile-uuids "$UPDATED_VALUE"
    fi
done