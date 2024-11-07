#!/usr/bin/bash
# shellcheck source=/dev/null
source /usr/lib/ujust/ujust.sh

###
# List of possible containers
###
targets=(
    "fedora-toolbox"
    "ubuntu-toolbox"
    "wolfi-toolbox"
    "wolfi-dx-toolbox"
)

###
# Exit Function
###
# shellcheck disable=SC2154
function Exiting(){
    echo "${red}Exiting...${normal}"
    echo "Rerun setup using ${blue}ujust configure-terminal${normal}..."
    exit 0
}
function Good_Exit(){
    echo ""
    echo "Finished Bluefin-CLI setup, rerun with ${blue}ujust bluefin-cli${normal} to reconfigure"
    exit 0
}

###
# Exit if string is empty
###
function String_check(){
    if test -z "$1"; then
        Exiting
    fi
}

###
# Trap function
###
# shellcheck disable=SC2317
function ctrl_c(){
    printf "\nSignal SIGINT caught\n"
    Exiting
}

###
# Choose if you want to use the Host or Container for first terminal
###
function Terminal_choice(){
    TERMINAL_CHOICE=$(Choose Host Container)
    if test "$TERMINAL_CHOICE" = "Host"; then
        echo "You have chosen to use Host Terminal."
    fi
    String_check "$TERMINAL_CHOICE"
}

###
# If Host was chosen, ask if they still want to make a container
###
function Make_container(){
    MAKE_CONTAINER=0
    if test "$1" = "Host"; then
        echo "Would you still like to setup default container?"
        MAKE_CONTAINER=$(Confirm) 
    fi
    if test "$MAKE_CONTAINER" -eq 1; then
        printf "Not making a container. Existing containers will not be deleted...\n"
        Good_Exit
    fi
}

###
# Choose which container they want to use
###
function Choose_container(){
    echo "Which Container Toolbox would you like to use?"
    CONTAINER_CHOICE=$(Choose "${targets[@]}")
    String_check "$CONTAINER_CHOICE"
}

###
# Ask how they want to manage the container.
###
function Container_manager(){
    echo "Would you like to use ${blue}quadlets${normal} to manage your container?"
    echo ""
    echo "${blue}Quadlets automatically rebuild your container on login.${normal}"
    echo "They will always be on the latest image you have pulled."
    echo "However, ${red}manually installed packages using apk, apt, or dnf will not persist${normal}."
    CONTAINER_MANAGER=$(Choose Quadlet Distrobox)
    String_check "$CONTAINER_MANAGER"
}

###
# Check to see if the chosen container already exists as a quadlet.
# If it does ask to disable and remove it otherwise quit.
# Takes chosen container as an argument.
###
function Is_enabled_and_stop(){
    MATCH=0
    for i in "${targets[@]}"
    do
        Enabled=0
        Enabled=$(systemctl --user is-enabled "$i".target)
        if test "$Enabled" = "enabled" && test "$i" != "$1"; then
            echo "${red}$i${normal} is ${red}enabled${normal}."
            echo "Would you like to ${red}disable and stop container${red}?"
            Disable=$(Confirm) 
            if test "$Disable" -eq 0; then
                systemctl --user --now disable "$i".target
                if test "systemctl --user --quiet is-active $i.service"; then
                    systemctl --user stop "$i".service
                fi
            else
                printf "Not disabling and stopping existing container %s..." "$i"
            fi
            unset "$Disable" 
        elif test "$Enabled" = "enabled" && test "$i" = "$1"; then
            echo "${blue}$1 is already enabled${normal}..."
            MATCH=1
        fi
        unset "$Enabled"
    done
    if test "$MATCH" -eq 1; then
        Good_Exit
    fi
    unset $MATCH
}

###
# Check to see if the chosen container already exists.
# If it does ask to remove it otherwise exit.
# Takes chosen container as an argument.
###
function Already_exists_and_rm(){
    for i in "${targets[@]}" 
    do
        Exists=0
        Exists=$(podman ps --all --filter name="$i" | grep -q " $i\$" && echo "1" || echo "0")
        if test "$Exists" -eq 1 && test "$i" = "$1"; then
            echo "$1 ${red}exists${normal}, would you like to ${red}delete it?${normal}"
            Delete=$(Confirm)
            if test "$Delete" -eq 0; then
                echo "Removing $1..."
                podman rm --force "$1"
            else
                echo "Reuisng existing $1 container."
                Good_Exit
            fi
            unset "$Delete"
        elif test "$Exists" -eq 1 && test "$i" != "$1"; then
            echo "$i exists, would you like to ${red}delete it?${normal}"
            Delete=$(Confirm)
            if test "$Delete" -eq 0; then
                echo "Removing $i..."
                podman rm --force "$i"
            else
                echo "Not removing $i..."
            fi
            unset "$Delete"
        fi
        unset "$Exists"
    done
}

###
# Build the container. Takes 3 inputs. 1: if you build it. 2: Container Manager. 3: The actual container
###
function Build_container(){
    if test "$1" -eq 1; then
        printf "Not Building a container..."
        Exiting
    fi
    if test "$2" = "Quadlet"; then
        echo "${blue}Building container using a Quadlet${normal}"
        echo ""
        systemctl --user enable "$3".target
        systemctl --user restart "$3".service
    elif test "$2" = "Distrobox"; then
        echo "${blue}Building container using a Distrobox${normal}"
        echo ""
        distrobox-create --nvidia --no-entry -Y --image "ghcr.io/ublue-os/${3}" --name "$3"
    else
        printf "Unkown Choice..."
        Exiting
    fi
}

###
# If ~/.bashrc.d exists and Chose Container for terminal. Make a symlink from /usr/share/ublue-os for first time shell.
# If Host was chosen. Remove existing symlink.
###
# function Make_bashrc_d_file(){
#     if test -d "${HOME}/.bashrc.d" && test "$1" = "Host"; then
#             echo "${red}Removing existing ~/.bashrc.d/00-container.sh if it exists${normal}."
#             test -f "${HOME}/.bashrc.d/00-container.sh" && rm "${HOME}/.bashrc.d/00-container.sh"
#     elif test -d "${HOME}/.bashrc.d"; then
#         echo "Setting first terminal be Container for bash using ~/.bashrc.d"
#         echo "Enter into container using ptyxis's menu after first entry"
#         echo "${blue}This requires your bash shell to source files in ~/.bashrc.d/${normal}"
#         test -e "${HOME}/.bashrc.d/00-container.sh" && rm "${HOME}/.bashrc.d/00-container.sh"
#         cp "/usr/share/ublue-os/bluefin-cli/${2}.sh" "${HOME}/.bashrc.d/00-container.sh"
#     else
#         echo "${red}Not implemented for non-Bash shells${normal} at this time..."
#     fi
# }

function main(){
    trap ctrl_c SIGINT
    printf "Set up containers\n"
    Terminal_choice
    Make_container "$TERMINAL_CHOICE" 
    Container_manager
    Choose_container
    Is_enabled_and_stop "$CONTAINER_CHOICE"
    Already_exists_and_rm "$CONTAINER_CHOICE" 
    Build_container "$MAKE_CONTAINER" "$CONTAINER_MANAGER" "$CONTAINER_CHOICE"
    Good_Exit
}

main
