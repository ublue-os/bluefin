#!/usr/bin/env bash

set -euo pipefail

echo "Running all privileged units"

pkexec /usr/bin/ublue-privileged-setup
