# vim: set ft=make :

alias upgrade := update

# Update system, flatpaks, and containers all at once
update:
    #!/usr/bin/bash
    rpm-ostree upgrade
    flatpak update -y
    brew update

alias auto-update := toggle-updates

# Turn automatic updates on or off
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled rpm-ostreed-automatic.timer  | grep -q enabled; then
        CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "prompt" ]; then
        echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
        echo "Enable or Disable automatic updates?"
        OPTION=$(ugum choose Enable Disable)
    elif [ "$OPTION" == "help" ]; then
        echo "Usage: ujust toggle-updates <option>"
        echo "  <option>: Specify the quick option - 'enable' or 'disable'"
        echo "  Use 'enable' to Enable automatic updates."
        echo "  Use 'disable' to Disable automatic updates."
        exit 0
    fi
    if [ "${OPTION,,}" == "enable" ]; then
        sudo systemctl enable rpm-ostreed-automatic.timer
    elif [ "${OPTION,,}" == "disable" ]; then
        sudo systemctl disable rpm-ostreed-automatic.timer
    fi

alias changelog := changelogs

# Show the changelog
changelogs:
    rpm-ostree db diff --changelogs
