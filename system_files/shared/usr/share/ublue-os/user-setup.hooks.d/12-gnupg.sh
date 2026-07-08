#!/usr/bin/bash
# Configure gpg-agent to find scdaemon, which moved to /usr/libexec in Fedora 43+
if [[ -f /usr/libexec/scdaemon ]]; then
    mkdir -p "${HOME}/.gnupg"
    chmod 700 "${HOME}/.gnupg"
    if ! grep -q "scdaemon-program" "${HOME}/.gnupg/gpg-agent.conf" 2>/dev/null; then
        echo "scdaemon-program /usr/libexec/scdaemon" >> "${HOME}/.gnupg/gpg-agent.conf"
    fi
fi
