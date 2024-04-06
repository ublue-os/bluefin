#!/usr/bin/bash

# Read the current value of the array
CURRENT_VALUE=$(dconf read /org/gnome/Ptyxis/profile-uuids)
guid="$1"

# remove the leading and trailing brackets
CURRENT_VALUE=${CURRENT_VALUE:1:-1}

# remove any spaces
CURRENT_VALUE=${CURRENT_VALUE// /}

# split the string into an array
IFS=',' read -r -a array <<<"$CURRENT_VALUE"

# Exit if the guid already is in the array
[[ $CURRENT_VALUE =~ $guid ]] && exit 0

# add the new value
array+=("'$guid'")

# join the array back into a string
UPDATED_VALUE=$(printf "%s," "${array[@]}")

# remove the trailing comma
UPDATED_VALUE=${UPDATED_VALUE%?}

# add the leading and trailing brackets
UPDATED_VALUE="[$UPDATED_VALUE]"

# Write the updated array back to dconf
dconf write /org/gnome/Ptyxis/profile-uuids "$UPDATED_VALUE"
