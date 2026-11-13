#!/usr/bin/env bash

set -euo pipefail

echo "Running all privileged units"

/usr/bin/pkexec /usr/bin/ublue-privileged-setup
