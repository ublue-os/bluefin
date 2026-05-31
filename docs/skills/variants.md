# Bluefin Variant Matrix

Complete reference for the image × tag × flavor build matrix.

## When to Use

- Deciding which image/tag/flavor combination to build or reference
- Explaining Bluefin variants to others (users, contributors)
- Understanding which Fedora version maps to which stream tag
- Identifying the correct OCI image path on `ghcr.io/ublue-os`

## When NOT to Use

- Building images (use [docs/skills/build.md](docs/skills/build.md))
- Changing stream tag behavior — this is a reference skill only
- LTS-specific questions — use [docs/skills/lts.md](docs/skills/lts.md)
- **NEVER use the VS Code Flatpak for development.** It is on the Bluefin blocklist due to sandbox limitations with devcontainers and SDKs. Install it via Homebrew using `brew install ublue-os/tap/visual-studio-code-linux` instead of layering RPMs.

## How It Works

Bluefin produces images as a matrix of three dimensions. The Justfile encodes this.

## Full Matrix

```
Images:  bluefin, bluefin-dx
Flavors: main, nvidia-open
Tags:    gts, stable, latest, beta
```

### Tags (Fedora Version)

| Tag | Fedora | Audience | Notes |
|---|---|---|---|
| `gts` | F42 | Most users | "Good Till September" — long support |
| `stable` | F42 | General use | Current stable |
| `latest` | F42/43 | Early adopters | Tracks latest Fedora |
| `beta` | F42/43 | Testers | Upcoming changes |

### Images

| Image | Description |
|---|---|
| `bluefin` | Base GNOME desktop — for general users |
| `bluefin-dx` | Developer experience — adds dev tools, devcontainer support |

### Flavors

| Flavor | GPU Support |
|---|---|
| `main` | AMD/Intel GPUs, open drivers |
| `nvidia-open` | NVIDIA GPUs using open kernel module |

## OCI Registry

```
ghcr.io/ublue-os/bluefin:TAG-FLAVOR
ghcr.io/ublue-os/bluefin:stable-main
ghcr.io/ublue-os/bluefin:latest-nvidia-open
ghcr.io/ublue-os/bluefin-dx:gts-main
```

## Related Repos

| Repo | Purpose |
|---|---|
| `~/src/bluefin` | Main image (base + dx) |
| `~/src/bluefin-lts` | LTS variant (CentOS base) |
| `~/src/bluefin-common` | Shared layer for all variants |
| `~/src/aurora` | KDE Plasma variant (parallel project) |

## Learnings

<!-- Background agents append here automatically -->
