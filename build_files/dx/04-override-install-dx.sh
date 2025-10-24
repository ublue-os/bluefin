#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

ghcurl "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" --retry 3 -o /tmp/kind
chmod +x /tmp/kind
mv /tmp/kind /usr/bin/kind

echo "::endgroup::"
