# Bluefin Security Model

Security-critical patterns for Bluefin image builds.

## When to Use

- Adding or reviewing a COPR repository in `build_files/base/04-packages.sh`
- Verifying or debugging cosign image signing
- Working with secureboot kernel module signing
- Evaluating whether a third-party package source is safe to add

## When NOT to Use

- Adding standard Fedora packages (no COPR) — use [docs/skills/packages.md](docs/skills/packages.md)
- General build issues unrelated to signing or package isolation — use [docs/skills/build.md](docs/skills/build.md)
- ISO signing questions — use [docs/skills/iso.md](docs/skills/iso.md)

## How It Works

Bluefin uses several layers of supply chain security. Understand before modifying
any package management or signing configuration.

## COPR Package Isolation (Critical)

```bash
# In build_files/base/04-packages.sh:
FEDORA_PACKAGES=(
    package-one
    package-two
)

COPR_PACKAGES=(
    copr-owner/copr-name:package-name
)
```

**FEDORA_PACKAGES and COPR_PACKAGES must ALWAYS stay separate.**
- `copr_install_isolated()` installs COPR packages in a sandboxed environment
- This prevents a malicious COPR package from injecting into the Fedora package set
- Mixing the arrays would bypass this protection

Validate after any change: `bash -n build_files/base/04-packages.sh`

## Cosign Image Verification

All production images are signed with cosign:
```bash
# Verify an image
just verify-container IMAGE ghcr.io/ublue-os cosign.pub

# Manual cosign verify
cosign verify --key cosign.pub ghcr.io/ublue-os/IMAGE:TAG
```

## Secureboot

Bluefin supports secureboot via signed kernel modules:
```bash
just secureboot bluefin latest main
```

## Adding Untrusted Sources

If asked to add a package from an untrusted source:
1. **Stop** — confirm with user before proceeding
2. Evaluate: is this a well-known COPR or an unknown third party?
3. Known-good COPRs are documented in existing `build_files/` scripts
4. Unknown COPRs require explicit user approval

## Learnings

<!-- Background agents append here automatically -->
