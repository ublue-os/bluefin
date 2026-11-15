set allow-duplicate-recipes := true
set ignore-comments := true

_default:
    #!/usr/bin/bash
    echo "https://docs.projectbluefin.io/administration#community-aliases-and-workarounds"
    ujust --list --list-heading $'Available commands:\n' --list-prefix $' - '

# Imports

import "/usr/share/ublue-os/just/apps.just"
import "/usr/share/ublue-os/just/changelog.just"
import "/usr/share/ublue-os/just/default.just"
import "/usr/share/ublue-os/just/shared.just"
import "/usr/share/ublue-os/just/system.just"
import "/usr/share/ublue-os/just/update.just"
import? "/usr/share/ublue-os/just/60-custom.just"
