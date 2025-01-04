#!/bin/bash
set -eoux pipefail
JUST_VERSION=$(curl --retry 3 --retry-all-errors -L https://api.github.com/repos/casey/just/releases/latest | jq -r '.tag_name')
if [[ "${JUST_VERSION}" == "null" ]]; then
  JUST_VERSION=1.38.0
fi
curl -sSLO https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz
tar -zxvf just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz -C /tmp just
sudo mv /tmp/just /usr/local/bin/just
rm -f just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz
