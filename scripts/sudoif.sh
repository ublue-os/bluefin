#!/usr/bin/bash
function sudoif(){
    if [[ "${TERM_PROGRAM}" == "vscode" ]]; then
        if [[ ! -f /run/.containerenv || ! -f /.dockerenv ]]; then
            /usr/bin/systemd-run --uid=0 --gid=0 -d -E TERM="$TERM" -t -q -P -G "$@"
        else
            /usr/bin/sudo "$@"
        fi
    fi
}