
#!/usr/bin/bash

set -eoux pipefail

# Add Staging repo
dnf5 -y -q copr enable ublue-os/staging
dnf5 -y -q copr enable sentry/switcheroo-control_discrete
dnf5 -y -q copr enable che/nerd-fonts
