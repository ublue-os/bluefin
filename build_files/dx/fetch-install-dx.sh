#!/usr/bin/bash

set -ouex pipefail

curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
chmod +x ./kind
mv ./kind /usr/bin/kind
