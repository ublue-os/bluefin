set allow-duplicate-recipes := true
set ignore-comments := true

_default:
    #!/usr/bin/bash
    source /usr/lib/ujust/libformatting.sh
    echo "$(Urllink "https://docs.projectbluefin.io/administration#community-aliases-and-workarounds" "Click here to view the Universal Blue just documentation")"
    /usr/bin/ujust --list --list-heading $'Available commands:\n' --list-prefix $' - '

# Imports
import "/usr/share/ublue-os/just/default.just"
import "/usr/share/ublue-os/just/update.just"
import "/usr/share/ublue-os/just/bluefin-apps.just"
import "/usr/share/ublue-os/just/bluefin-system.just"
