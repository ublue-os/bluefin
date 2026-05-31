# Bluefin Package Management

Covers brew, flatpak, RPM/DNF, and COPR package management in Bluefin.

## When to Use

- Adding, removing, or updating brew formulas in the `brew/` directory
- Adding or removing Flatpak app IDs in the `flatpaks/` directory
- Adding RPM packages to `FEDORA_PACKAGES` in `build_files/base/04-packages.sh`
- Adding COPR packages to `COPR_PACKAGES` (security-isolated)

## When NOT to Use

- Changes to the `Containerfile` build logic — use [docs/skills/build.md](docs/skills/build.md)
- Security policy questions about COPR isolation — use [docs/skills/security.md](docs/skills/security.md)
- CI failures after a package change — use [docs/skills/ci.md](docs/skills/ci.md)

## How It Works

Packages live in different places depending on type. Wrong location = broken builds.
Run `bash /mnt/skills/user/bluefin-packages/scripts/add-package.sh` for guided workflow.

## Package Locations

| Type | Location | Notes |
|---|---|---|
| RPM (Fedora) | `build_files/base/04-packages.sh` → `FEDORA_PACKAGES` | Standard dnf packages |
| COPR RPM | `build_files/base/04-packages.sh` → `COPR_PACKAGES` | **Must stay separate — security** |
| Flatpak | `flatpaks/` directory | Per-stream flatpak lists |
| Homebrew | `brew/` directory | Brewfiles per variant |
| DX packages | `build_files/dx/` | Developer experience packages only |

## ⚠️ COPR Security Model (Critical)

`FEDORA_PACKAGES` and `COPR_PACKAGES` arrays **must remain separate**.
COPR repos are isolated via `copr_install_isolated()` to prevent malicious package injection.
**Never mix COPR and Fedora packages in the same array.**

```bash
# Validate shell script syntax after changes
bash -n build_files/base/04-packages.sh
```

## Adding an RPM Package

```bash
# 1. Add to correct array in build_files/base/04-packages.sh
# 2. Validate syntax
bash -n build_files/base/04-packages.sh
# 3. Run validation
just check
```

## Adding a Flatpak

```bash
# Add app ID to appropriate file in flatpaks/
# File naming follows stream convention
```

## Adding a Brew Formula

```bash
# Add to appropriate Brewfile in brew/
# Check brew/ directory structure for correct file
```

## Output

add-package.sh guides you through the correct location and validates after change.

## Troubleshooting

- Package not found: verify it's in Fedora repos (`dnf search PACKAGE`)
- COPR package: enable the COPR repo first, add to `COPR_PACKAGES` only
- Build failure after adding package: check script syntax with `bash -n`

## Learnings

<!-- Background agents append here automatically -->
