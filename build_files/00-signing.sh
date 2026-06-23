#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Container Signing Policy Setup
###############################################################################
# Installs the cosign public key and configures /etc/containers/policy.json
# to require sigstore signature verification for all images at ghcr.io/lbssousa.
#
# This makes bootc upgrade report "ostree-image-signed:" instead of
# "ostree-unverified-registry:", and prevents unsigned images from being
# applied to the system.
###############################################################################

echo "::group:: Configure Image Signing Policy"

install -Dm0644 /ctx/cosign.pub /usr/lib/pki/containers/lbssousa.pub

jq '.transports.docker["ghcr.io/lbssousa"] = [
  {
    "type": "sigstoreSigned",
    "keyPath": "/usr/lib/pki/containers/lbssousa.pub",
    "signedIdentity": { "type": "matchRepository" }
  }
]' /etc/containers/policy.json > /tmp/policy.json.tmp
mv /tmp/policy.json.tmp /etc/containers/policy.json

cat > /etc/containers/registries.d/ghcr.io-lbssousa.yaml << 'EOF'
docker:
  ghcr.io/lbssousa:
    use-sigstore-attachments: true
EOF

echo "::endgroup::"
